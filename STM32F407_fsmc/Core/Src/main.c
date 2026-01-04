/* USER CODE BEGIN Header */
/**
 ******************************************************************************
 * @file           : main.c
 * @brief          : Main program body
 ******************************************************************************
 * @attention
 *
 * Copyright (c) 2025 STMicroelectronics.
 * All rights reserved.
 *
 * This software is licensed under terms that can be found in the LICENSE file
 * in the root directory of this software component.
 * If no LICENSE file comes with this software, it is provided AS-IS.
 *
 ******************************************************************************
 */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "fsmc.h"
#include "gpio.h"
#include "usart.h"
#include "usb_device.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "usbd_core.h"
#include "usbd_cdc_if.h"
#include <stdio.h>
#include <string.h>
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define CHANNEL_COUNT      16
#define READ_CHANNEL_COUNT 16
#define CMD_BUFFER_SIZE    64

/* --- 根据 FSMC 手册定义的 FPGA 寄存器访问 --- */
#define FPGA_BASE_ADDR 0x60000000
#define FPGA_REG(n)    (*(volatile uint16_t *)(FPGA_BASE_ADDR + (n) * 2))

// 控制寄存器 (写 0x0000) 位定义
#define CTRL_ENABLE   (1 << 0)  // 1=STM32接管控制, 0=触摸控制
#define CTRL_HDMI     (1 << 1)  // 1=HDMI, 0=LCD
#define CTRL_ACTIVE   (1 << 2)  // 1=动态显示, 0=冻结
#define CTRL_CAM_RST  (1 << 3)  // 重启摄像头采集 (脉冲)
#define CTRL_SOFT_RST (1 << 15) // 软复位 (脉冲)

// 图像处理控制 (写 0x0003) & 阈值 (写 0x0004) 位定义
#define IMG_CTRL_ENABLE (1 << 15) // 1=FSMC控制, 0=长按切换
#define ALGO_MODE_MASK  0x07      // 模式掩码 (0-5)
#define ALGO_ORIGINAL   0
#define ALGO_GRAY       1
#define ALGO_BINARY     2
#define ALGO_SOBEL      3
#define ALGO_ERODE      4
#define ALGO_DILATE     5

// 系统状态寄存器 (读 0x0009) 位定义
#define STATUS_SYS_INIT    (1 << 0) // 系统初始化完成
#define STATUS_OUTPUT_MODE (1 << 1) // 0=LCD, 1=HDMI
#define STATUS_DISPLAY_ACT (1 << 2) // 1=动态显示, 0=冻结
#define STATUS_STM32_CTRL  (1 << 3) // STM32控制使能
#define STATUS_CAM_INIT    (1 << 4) // 摄像头初始化完成
#define STATUS_SDRAM_INIT  (1 << 5) // SDRAM初始化完成
#define STATUS_TOUCH_VALID (1 << 6) // 触摸有效

// 图像处理控制 (写 0x0003) & 阈值 (写 0x0004) 位定义
#define IMG_CTRL_ENABLE (1 << 15) // 1=FSMC控制, 0=长按切换
#define ALGO_MODE_MASK  0x07      // 模式掩码 (0-5)
#define ALGO_ORIGINAL   0
#define ALGO_GRAY       1
#define ALGO_BINARY     2
#define ALGO_SOBEL      3
#define ALGO_ERODE      4
#define ALGO_DILATE     5
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */
uint8_t usb_cmd_buffer[CMD_BUFFER_SIZE];
uint8_t cmd_idx               = 0;
volatile uint8_t cmd_received = 0;

// 发送环形缓冲区
#define USB_TX_BUF_SIZE 4096
uint8_t usb_tx_buffer[USB_TX_BUF_SIZE];

volatile uint32_t usb_tx_head = 0;
volatile uint32_t usb_tx_tail = 0;

// 添加对 usb_device.c 中定义的全局变量的 extern 声明
extern USBD_HandleTypeDef hUsbDeviceFS;
extern uint8_t UserRxBufferFS[APP_RX_DATA_SIZE];

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
/* USER CODE BEGIN PFP */
void ProcessUSBCommand(void);
void SendFPGADataToUSB(void);
void SendStringToUSB(const char *str);
void USB_TransmitHandle(void);
void TestUSBOutput(void);
void RW_FPGAReg(void);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
uint16_t data[READ_CHANNEL_COUNT]; // 数据缓存

void RW_FPGAReg()
{
    const char *mode_names[] = {"Original", "Grayscale", "Binary", "Sobel", "Erode", "Dilate"};
    SendStringToUSB("--- FPGA Image Algorithm Demo ---\r\n");

    // 启用图像处理控制
    for (int i = 0; i < 6; i++) {
        char buf[64];
        sprintf(buf, "Switching to Mode: %s\r\n", mode_names[i]);
        SendStringToUSB(buf);

        // 设置模式并根据需要设置二值化阈值(120)
        FPGA_REG(3) = (uint16_t)(IMG_CTRL_ENABLE | (i & 0x07));
        if (i == ALGO_BINARY) {
            FPGA_REG(4) = 120;
        }

        HAL_Delay(2000);
        USB_TransmitHandle();
    }

    // 恢复触摸控制模式
    FPGA_REG(3) = 0x0000;
    SendStringToUSB("Demo Completed. Image Control Restored to Touch.\r\n");
}

void SendStringToUSB(const char *str)
{
    uint32_t len = strlen(str);
    for (uint32_t i = 0; i < len; i++) {
        uint32_t next = (usb_tx_head + 1) % USB_TX_BUF_SIZE;
        if (next != usb_tx_tail) // 缓冲区未满
        {
            usb_tx_buffer[usb_tx_head] = str[i];
            usb_tx_head                = next;
        } else {
            // 缓冲区满，丢弃后续数据或在此等待（目前选择丢弃以保证实时性，
            // 2KB足够支撑大部分调试信息）
            break;
        }
    }
}

// 实际负责处理发送的函数，在主循环中调用
void USB_TransmitHandle(void)
{
    // 如果没有数据要发，直接返回
    if (usb_tx_head == usb_tx_tail) return;

    // 检查 USB 是否准备好
    USBD_CDC_HandleTypeDef *hcdc = (USBD_CDC_HandleTypeDef *)hUsbDeviceFS.pClassData;
    if (hcdc == NULL) return;

    if (hcdc->TxState == 0) // USB CDC 空闲
    {
        uint32_t current_tail = usb_tx_tail;
        uint32_t len          = 0;
        static uint8_t temp_buf[CDC_DATA_FS_MAX_PACKET_SIZE];

        // 计算本次可以发送的长度（不跨越缓冲区边界，且不超过最大包长）
        while (current_tail != usb_tx_head && len < CDC_DATA_FS_MAX_PACKET_SIZE) {
            temp_buf[len++] = usb_tx_buffer[current_tail];
            current_tail    = (current_tail + 1) % USB_TX_BUF_SIZE;
        }

        if (len > 0) {
            if (CDC_Transmit_FS(temp_buf, len) == USBD_OK) {
                usb_tx_tail = current_tail;
            }
        }
    }
}

void SendFPGADataToUSB(void)
{
    char buffer[160];
    const char *reg_desc[] = {
        "TOUCH_VALID_FLAG", "TOUCH_X_COORD   ", "TOUCH_Y_COORD   ", "LCD_ID          ",
        "CAM_H_PIXELS    ", "CAM_V_PIXELS    ", "LCD_READ_COUNT  ", "CAM_WRITE_COUNT ",
        "FRAME_COUNT     ", "SYSTEM_STATUS   ", "CTRL_REG_ECHO   ", "BRIGHTNESS_ECHO ",
        "CONTRAST_ECHO   ", "IMG_MODE_RD     ", "IMG_THRESH_RD   ",
        "WR_FORCED_CNT   ", // 0x0F: 强制同步计数器 (抖动核心指标)
        "FRAME_CNT_L     ", // 0x10: 调试用帧计数
        "PIXEL_CNT_L     ", // 0x11: 调试用像素计
        "PIXEL_CNT_H     ", // 0x12: 调试用像素计
        "SYNC_STATUS_BIT"   // 0x13: 同步状态位域
    };
    const char *algo_names[] = {"Original", "Grayscale", "Binary", "Sobel", "Erode", "Dilate"};

    sprintf(buffer, "\r\n--- FPGA Internal Status (Extended) [%lu ms] ---\r\n", HAL_GetTick());
    SendStringToUSB(buffer);

    for (int i = 0; i < 20; i++) {
        uint16_t val = FPGA_REG(i);
        sprintf(buffer, "0x%02X [%-16s] : 0x%04X (%d)\r\n", i, reg_desc[i], val, val);
        SendStringToUSB(buffer);

        if (i == 9) { // 额外解析状态寄存器
            sprintf(buffer, "   -> [INIT:%d, MODE:%s, ACT:%s, STM32:%d, CAM:%d, SDRAM:%d, TCH:%d]\r\n",
                    (val & STATUS_SYS_INIT) ? 1 : 0,
                    (val & STATUS_OUTPUT_MODE) ? "HDMI" : "LCD",
                    (val & STATUS_DISPLAY_ACT) ? "YES" : "FREEZE",
                    (val & STATUS_STM32_CTRL) ? 1 : 0,
                    (val & STATUS_CAM_INIT) ? 1 : 0,
                    (val & STATUS_SDRAM_INIT) ? 1 : 0,
                    (val & STATUS_TOUCH_VALID) ? 1 : 0);
            SendStringToUSB(buffer);
        } else if (i == 13) { // 算法模式解码
            uint8_t mode = val & ALGO_MODE_MASK;
            sprintf(buffer, "   -> Current Algorithm: %s (%d)\r\n",
                    (mode < 6) ? algo_names[mode] : "Unknown", mode);
            SendStringToUSB(buffer);
        } else if (i == 15) { // 强制同步计数器
            sprintf(buffer, "   -> [CRITICAL] VSYNC Forced Resets: %d times\r\n", val);
            SendStringToUSB(buffer);
        } else if (i == 19) { // 详细同步位域解析
            sprintf(buffer, "   -> [STATUS] Bank:%d, WrDone:%d, RdDone:%d, WrForced:%d, RdReq:%d\r\n",
                    (val & 0x01),         // bit 0: 当前写Bank
                    (val & 0x02) ? 1 : 0, // bit 1: 后端自动换Bank已完成
                    (val & 0x04) ? 1 : 0, // bit 2: 前端读完一帧
                    (val & 0x08) ? 1 : 0, // bit 3: 发生了强制Bank对齐脉冲
                    (val & 0x10) ? 1 : 0  // bit 4: 读复位申请脉冲
            );
            SendStringToUSB(buffer);
        }
        USB_TransmitHandle();
    }
    SendStringToUSB("---------------------------------------\r\n");
}

void ProcessUSBCommand(void)
{
    if (cmd_received) {
        if (usb_cmd_buffer[0] == 'r' || usb_cmd_buffer[0] == 'R') {
            SendStringToUSB("Scanning FPGA status...\r\n");
            SendFPGADataToUSB();
        } else if (usb_cmd_buffer[0] == 't' || usb_cmd_buffer[0] == 'T') {
            RW_FPGAReg();
        } else if (usb_cmd_buffer[0] == 'w' || usb_cmd_buffer[0] == 'W') {
            uint32_t addr, val;
            if (sscanf((char *)&usb_cmd_buffer[1], "%x %x", &addr, &val) == 2) {
                if (addr <= 4) { // 增加允许写入的地址范围 0x00-0x04
                    FPGA_REG(addr) = (uint16_t)val;
                    char msg[64];
                    sprintf(msg, "Written REG 0x%02X = 0x%04X\r\n", (unsigned int)addr, (unsigned int)val);
                    SendStringToUSB(msg);
                } else {
                    SendStringToUSB("Error: Only Addr 0x00-0x04 are writable.\r\n");
                }
            } else {
                SendStringToUSB("Usage: W [addr_hex] [val_hex]\r\n");
            }
        } else if (usb_cmd_buffer[0] == 'p' || usb_cmd_buffer[0] == 'P') // 快捷指令：算法设置: P mode [thresh]
        {
            int mode_val   = -1;
            int thresh_val = 127;
            // 跳过 'p' 后的空格
            char *p_args = (char *)&usb_cmd_buffer[1];
            while (*p_args == ' ') p_args++;

            int count = sscanf(p_args, "%d %d", &mode_val, &thresh_val);
            if (count >= 1 && mode_val >= 0 && mode_val <= 5) {
                uint16_t reg_val = (uint16_t)(IMG_CTRL_ENABLE | (mode_val & 0x07));
                FPGA_REG(3)      = reg_val;
                if (count == 2) FPGA_REG(4) = (uint16_t)thresh_val;

                char msg[128];
                sprintf(msg, "Set Algo Mode: %d, Threshold: %d (Reg3=0x%04X)\r\n",
                        mode_val, thresh_val, reg_val);
                SendStringToUSB(msg);
            } else {
                SendStringToUSB("Usage: P [mode 0-5] [threshold 0-255]\r\n");
            }
        } else if (usb_cmd_buffer[0] == 'f' || usb_cmd_buffer[0] == 'F') // 快捷指令：冻结画面
        {
            FPGA_REG(0) |= CTRL_ENABLE;
            FPGA_REG(0) &= ~CTRL_ACTIVE;
            SendStringToUSB("Display Frozen.\r\n");
        } else if (usb_cmd_buffer[0] == 'a' || usb_cmd_buffer[0] == 'A') // 快捷指令：激活画面
        {
            FPGA_REG(0) |= CTRL_ENABLE | CTRL_ACTIVE;
            SendStringToUSB("Display Active.\r\n");
        } else if (usb_cmd_buffer[0] == 'm' || usb_cmd_buffer[0] == 'M') // 快捷指令：切换 LCD/HDMI
        {
            uint16_t current = FPGA_REG(10); // 回读控制寄存器
            FPGA_REG(0)      = (current ^ CTRL_HDMI) | CTRL_ENABLE | CTRL_ACTIVE;
            SendStringToUSB("Output Mode Toggled.\r\n");
        } else if (usb_cmd_buffer[0] == 'l' || usb_cmd_buffer[0] == 'L') {
            HAL_GPIO_TogglePin(LED2_GPIO_Port, LED2_Pin);
            HAL_GPIO_TogglePin(LED3_GPIO_Port, LED3_Pin);
            SendStringToUSB("Toggled Board LEDs\r\n");
        } else if (usb_cmd_buffer[0] == 'h' || usb_cmd_buffer[0] == 'H') {
            SendStringToUSB("Manual Commands:\r\n");
            SendStringToUSB(" R/r - Read All Status\r\n");
            SendStringToUSB(" W/w [addr] [val] - Write Raw\r\n");
            SendStringToUSB(" P/p [mode] [thresh] - Set Image Algo\r\n");
            SendStringToUSB(" F/f - Freeze Frame\r\n");
            SendStringToUSB(" A/a - Resume Display\r\n");
            SendStringToUSB(" M/m - Toggle HDMI/LCD\r\n");
            SendStringToUSB(" T/t - Algo Demo Test\r\n");
            SendStringToUSB(" L/l - Board LED\r\n");
        } else {
            char unknown_cmd_msg[64];
            sprintf(unknown_cmd_msg, "Unknown: '%s'. Type 'H'.\r\n", usb_cmd_buffer);
            SendStringToUSB(unknown_cmd_msg);
        }

        cmd_received = 0;
        cmd_idx      = 0;
        SendStringToUSB("\r\n> ");
    }
}

void MainApplicationTask(void)
{
    static uint32_t last_fpga_tick = 0;
    static uint32_t welcome_sent   = 0;

    while (1) {
        // 处理 USB 发送和接收轮询
        USB_TransmitHandle();
        ProcessUSBCommand();

        // 延迟发送欢迎语，确保系统稳定
        if (!welcome_sent && HAL_GetTick() > 2000) {
            SendStringToUSB("\r\nSTM32-FPGA Communication System\r\n");
            SendStringToUSB("Type 'H' for help\r\n");
            SendStringToUSB("> ");
            welcome_sent = 1;
        }

        // 按照一定间隔执行后台维护任务 (可选)
        if (HAL_GetTick() - last_fpga_tick >= 1000) {
            last_fpga_tick = HAL_GetTick();
            // 这里可以添加一些非阻塞的后台检查
        }
    }
}

// 添加USB输出测试函数
void TestUSBOutput(void)
{
    // 输出一些测试字符，以验证USB CDC功能
    SendStringToUSB("USB CDC Test Output\r\n");
    SendStringToUSB("Hello from STM32F407!\r\n");
    SendStringToUSB("This is a RW_FPGAReg message.\r\n");

    // 输出数字和字符
    for (int i = 0; i < 10; i++) {
        char buffer[32];
        sprintf(buffer, "Count: %d\r\n", i);
        SendStringToUSB(buffer);
    }

    SendStringToUSB("RW_FPGAReg completed.\r\n");
}

// USB CDC 接收逻辑将移至 usbd_cdc_if.c 或通过特定接口调用
// 此处删除原有的 CDC_Receive_FS 重定义以避免冲突
void USB_DataReceived_Handler(uint8_t *Buf, uint32_t Len)
{
    for (uint32_t i = 0; i < Len; i++) {
        if (Buf[i] == '\r' || Buf[i] == '\n') {
            if (cmd_idx > 0) {
                usb_cmd_buffer[cmd_idx] = 0;
                cmd_received            = 1;
                // 回车换行回显
                SendStringToUSB("\r\n");
            }
        } else if (Buf[i] == 0x08 || Buf[i] == 0x7F) { // 退格键 (Backspace 或 Delete)
            if (cmd_idx > 0) {
                cmd_idx--;
                // 退格回显：光标左移 -> 空格覆盖 -> 光标左移
                SendStringToUSB("\b \b");
            }
        } else {
            if (cmd_idx < CMD_BUFFER_SIZE - 1) {
                if ((Buf[i] >= 32 && Buf[i] <= 126) || Buf[i] == '\t') {
                    usb_cmd_buffer[cmd_idx++] = Buf[i];

                    // 单字符回显
                    char echo_str[2] = {(char)Buf[i], 0};
                    SendStringToUSB(echo_str);
                }
            }
        }
    }
}

/* USER CODE END 0 */

/**
 * @brief  The application entry point.
 * @retval int
 */
int main(void)
{

    /* USER CODE BEGIN 1 */
    /* USER CODE END 1 */

    /* MCU Configuration--------------------------------------------------------*/

    /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
    HAL_Init();

    /* USER CODE BEGIN Init */

    /* USER CODE END Init */

    /* Configure the system clock */
    SystemClock_Config();

    /* USER CODE BEGIN SysInit */

    /* USER CODE END SysInit */

    /* Initialize all configured peripherals */
    MX_GPIO_Init();
    MX_FSMC_Init();
    MX_USART1_UART_Init();
    MX_USART2_UART_Init();
    MX_USART3_UART_Init();
    MX_USB_DEVICE_Init();
    /* USER CODE BEGIN 2 */
    // 初始化USB接收
    // 等待USB设备连接
    HAL_Delay(1000);

    // 确保USB CDC接收已启动
    uint8_t result = USBD_CDC_ReceivePacket(&hUsbDeviceFS);
    if (result != USBD_OK) {
        // 如果接收启动失败，可以尝试发送错误信息
        char error_msg[] = "USB CDC ReceivePacket failed\r\n";
        CDC_Transmit_FS((uint8_t *)error_msg, strlen(error_msg));
    }

    /* USER CODE END 2 */

    /* Infinite loop */
    /* USER CODE BEGIN WHILE */
    MainApplicationTask(); // 调用整合后的功能函数
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
    return 0;
    /* USER CODE END 3 */
}

/**
 * @brief System Clock Configuration
 * @retval None
 */
void SystemClock_Config(void)
{
    RCC_OscInitTypeDef RCC_OscInitStruct = {0};
    RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

    /** Configure the main internal regulator output voltage
     */
    __HAL_RCC_PWR_CLK_ENABLE();
    __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

    /** Initializes the RCC Oscillators according to the specified parameters
     * in the RCC_OscInitTypeDef structure.
     */
    RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
    RCC_OscInitStruct.HSEState       = RCC_HSE_ON;
    RCC_OscInitStruct.PLL.PLLState   = RCC_PLL_ON;
    RCC_OscInitStruct.PLL.PLLSource  = RCC_PLLSOURCE_HSE;
    RCC_OscInitStruct.PLL.PLLM       = 4;
    RCC_OscInitStruct.PLL.PLLN       = 168;
    RCC_OscInitStruct.PLL.PLLP       = RCC_PLLP_DIV2;
    RCC_OscInitStruct.PLL.PLLQ       = 7;
    if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK) {
        Error_Handler();
    }

    /** Initializes the CPU, AHB and APB buses clocks
     */
    RCC_ClkInitStruct.ClockType      = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
    RCC_ClkInitStruct.SYSCLKSource   = RCC_SYSCLKSOURCE_PLLCLK;
    RCC_ClkInitStruct.AHBCLKDivider  = RCC_SYSCLK_DIV1;
    RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
    RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;

    if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_5) != HAL_OK) {
        Error_Handler();
    }
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
 * @brief  This function is executed in case of error occurrence.
 * @retval None
 */
void Error_Handler(void)
{
    /* USER CODE BEGIN Error_Handler_Debug */
    /* User can add his own implementation to report the HAL error return state */
    __disable_irq();
    while (1) {
    }
    /* USER CODE END Error_Handler_Debug */
}

#ifdef USE_FULL_ASSERT
/**
 * @brief  Reports the name of the source file and the source line number
 *         where the assert_param error has occurred.
 * @param  file: pointer to the source file name
 * @param  line: assert_param error line source number
 * @retval None
 */
void assert_failed(uint8_t *file, uint32_t line)
{
    /* USER CODE BEGIN 6 */
    /* User can add his own implementation to report the file name and line number,
       ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
    /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
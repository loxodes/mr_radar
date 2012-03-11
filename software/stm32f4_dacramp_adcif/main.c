/*
    mr_radar vco control and adc
    this is my first stm32 project, the code is messay
    and hacked from example code

    generates sawtooth ramp for VCO
    captures samples and dumps them over the serial port

    for the stm32f4 discovery board
    code is adapted from st micro stm32 code examples

    adapted from texane's stlink makefiles
*/

#include "stm32f4xx_conf.h"
#include "stm32f4_discovery.h"

#define DAC_DHR12R2_ADDRESS    0x40007414
#define DAC_DHR12R1_ADDRESS    0x40007408
#define ADC3_DR_ADDRESS        0x4001224C  

#define RAMP_LENGTH 512 
#define TRIGGER_LEN 10
#define ADC_BUFFER_LEN 16384 

DAC_InitTypeDef DAC_InitStructure;

uint16_t Ramp12bit[RAMP_LENGTH];
uint16_t Trigger12bit[RAMP_LENGTH];
uint16_t ADC_Buffer[ADC_BUFFER_LEN];

__IO uint8_t KeyPressed = 1; 

void TIM6_Config(void);
void DAC_Ch1_TriggerConfig(void);
void DAC_Ch2_RampConfig(void);
void ADC3_CH12_DMA_Config(void);
void USART_Config(void);
void Usart3Put(uint8_t ch);
void USART_BufferBlast(void); 
uint8_t Usart3Get(void);

int main(void)
{
  uint16_t i;
  
  GPIO_InitTypeDef GPIO_InitStructure;
  
  STM_EVAL_LEDInit(LED4);
  STM_EVAL_LEDInit(LED3);
  STM_EVAL_LEDInit(LED5);
  STM_EVAL_LEDInit(LED6);

  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_DMA1 | RCC_AHB1Periph_GPIOA, ENABLE);
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_DAC, ENABLE);
  
  // DAC channel 1 & 2 (DAC_OUT1 = PA.4)(DAC_OUT2 = PA.5) configuration 
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4 | GPIO_Pin_5;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  TIM6_Config();  
  
  for(i=0; i<RAMP_LENGTH; i++) {
    Ramp12bit[i] = i<<3;
    Trigger12bit[i] = i < TRIGGER_LEN ? 0xFFF : 0;
  }
  
  STM_EVAL_PBInit(BUTTON_USER, BUTTON_MODE_EXTI);
  
  DAC_InitStructure.DAC_Trigger = DAC_Trigger_T6_TRGO;
  DAC_InitStructure.DAC_WaveGeneration = DAC_WaveGeneration_None;
  DAC_InitStructure.DAC_OutputBuffer = DAC_OutputBuffer_Enable;
  DAC_Init(DAC_Channel_1, &DAC_InitStructure);
  DAC_Init(DAC_Channel_2, &DAC_InitStructure);

  DAC_Ch2_RampConfig();
  DAC_Ch1_TriggerConfig();

  USART_Config();
  
  ADC3_CH12_DMA_Config(); 
  ADC_SoftwareStartConv(ADC3);
 
  STM_EVAL_LEDOn(LED5);
    
  while (1)
  {
    if(Usart3Get() == 'r') {
        STM_EVAL_LEDOn(LED6);
        // blast out adc over serial
        ADC_DMARequestAfterLastTransferCmd(ADC3, DISABLE);
        USART_BufferBlast();

        STM_EVAL_LEDOn(LED3);
        
        // not the most elegant solution...
        ADC_DeInit();
        DMA_DeInit(DMA2_Stream0);
        ADC3_CH12_DMA_Config(); 
        ADC_SoftwareStartConv(ADC3);

  //      KeyPressed = 1;
    }
  }
}

void USART_BufferBlast(void)
{
    uint16_t i;
    for(i=0;i<10;i++){
        Usart3Put(0x55);
    }
    Usart3Put('s');
    Usart3Put('t');
    Usart3Put('a');
    Usart3Put('r');
    Usart3Put('t');
    for(i=0;i<ADC_BUFFER_LEN;i++) {
        if(ADC_Buffer[i] > 0x1FF)
            STM_EVAL_LEDOn(LED4);
        else
            STM_EVAL_LEDOff(LED4);
        Usart3Put((ADC_Buffer[i]) & 0xFF);
        Usart3Put((ADC_Buffer[i] >> 8) & 0xFF);
        ADC_Buffer[i] = 0;
    }
    Usart3Put('s');
    Usart3Put('t');
    Usart3Put('o');
    Usart3Put('p');
}

// TIM6 configuration is based on CPU @168MHz and APB1 @42MHz
void TIM6_Config(void)
{
  TIM_TimeBaseInitTypeDef    TIM_TimeBaseStructure;
  /* TIM6 Periph clock enable */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM6, ENABLE);

  /* Time base configuration */
  TIM_TimeBaseStructInit(&TIM_TimeBaseStructure);
  TIM_TimeBaseStructure.TIM_Period = 0x1F;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up; 
  TIM_TimeBaseInit(TIM6, &TIM_TimeBaseStructure);

  /* TIM6 TRGO selection */
  TIM_SelectOutputTrigger(TIM6, TIM_TRGOSource_Update);
  
  /* TIM6 enable counter */
  TIM_Cmd(TIM6, ENABLE);
}

void USART_Config(void)
{
  // https://my.st.com/public/STe2ecommunities/mcu/Lists/STM32Discovery/Flat.aspx?RootFolder=%2fpublic%2fSTe2ecommunities%2fmcu%2fLists%2fSTM32Discovery%2fUART%20connection&FolderCTID=0x01200200770978C69A1141439FE559EB459D75800084C20D8867EAD444A5987D47BE638E0F&currentviews=50
  // http://www.embedds.com/programming-stm32-usart-using-gcc-tools-part-1/ 
  // http://tech.munts.com/MCU/Frameworks/ARM/stm32f4/serial.c

  USART_InitTypeDef USART_InitStructure;
  GPIO_InitTypeDef GPIO_InitStructure;
  
  // enable bus clocks
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOD, ENABLE);
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART3, ENABLE);
  
  GPIO_PinAFConfig(GPIOD, GPIO_PinSource8, GPIO_AF_USART2);
  GPIO_PinAFConfig(GPIOD, GPIO_PinSource9, GPIO_AF_USART2);
  
  // configure tx pin  
  GPIO_StructInit(&GPIO_InitStructure);
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_Init(GPIOD, &GPIO_InitStructure);

  // configure rx pin
  GPIO_StructInit(&GPIO_InitStructure);
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_UP;
  GPIO_Init(GPIOD, &GPIO_InitStructure);


  // set USART for 9600 baud, 1 stop no parity
  USART_StructInit(&USART_InitStructure);
  //https://my.st.com/public/STe2ecommunities/mcu/Lists/STM32Discovery/DispForm.aspx?ID=1563&RootFolder=%2Fpublic%2FSTe2ecommunities%2Fmcu%2FLists%2FSTM32Discovery%2F[STM32F4-Discovery]%20UART4%20Problem
  USART_InitStructure.USART_BaudRate = 30000; // not really, actually 9600.. see above link
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No ;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_Init(USART3, &USART_InitStructure);  
  USART_Cmd(USART3, ENABLE);
}

void Usart3Put(uint8_t ch)
{
    //USART3->DR = (ch & (uint16_t)0x01FF);
    USART_SendData(USART3, (uint8_t) ch);
      //Loop until the end of transmission
    while(USART_GetFlagStatus(USART3, USART_FLAG_TC) == RESET)
     {
     }
}

uint8_t Usart3Get(void){
     while ( USART_GetFlagStatus(USART3, USART_FLAG_RXNE) == RESET);
        return (uint8_t)USART_ReceiveData(USART3);
}

void ADC3_CH12_DMA_Config(void)
{
  ADC_InitTypeDef       ADC_InitStructure;
  ADC_CommonInitTypeDef ADC_CommonInitStructure;
  DMA_InitTypeDef       DMA_InitStructure;
  GPIO_InitTypeDef      GPIO_InitStructure;

  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_DMA2 | RCC_AHB1Periph_GPIOC, ENABLE);
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC3, ENABLE);

  DMA_InitStructure.DMA_Channel = DMA_Channel_2;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)ADC3_DR_ADDRESS;
  DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)&ADC_Buffer;
  DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  DMA_InitStructure.DMA_BufferSize = ADC_BUFFER_LEN;
  DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
  DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
  DMA_InitStructure.DMA_Mode = DMA_Mode_Circular;
  DMA_InitStructure.DMA_Priority = DMA_Priority_High;
  DMA_InitStructure.DMA_FIFOMode = DMA_FIFOMode_Disable;         
  DMA_InitStructure.DMA_FIFOThreshold = DMA_FIFOThreshold_HalfFull;
  DMA_InitStructure.DMA_MemoryBurst = DMA_MemoryBurst_Single;
  DMA_InitStructure.DMA_PeripheralBurst = DMA_PeripheralBurst_Single;
  DMA_Init(DMA2_Stream0, &DMA_InitStructure);
  DMA_Cmd(DMA2_Stream0, ENABLE);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_2;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOC, &GPIO_InitStructure);

  ADC_CommonInitStructure.ADC_Mode = ADC_Mode_Independent;
  ADC_CommonInitStructure.ADC_Prescaler = ADC_Prescaler_Div4;
  ADC_CommonInitStructure.ADC_DMAAccessMode = ADC_DMAAccessMode_Disabled;
  ADC_CommonInitStructure.ADC_TwoSamplingDelay = ADC_TwoSamplingDelay_5Cycles;
  ADC_CommonInit(&ADC_CommonInitStructure);

  ADC_InitStructure.ADC_Resolution = ADC_Resolution_12b;
  ADC_InitStructure.ADC_ScanConvMode = DISABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConvEdge = ADC_ExternalTrigConvEdge_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfConversion = 1;
  ADC_Init(ADC3, &ADC_InitStructure);

  ADC_RegularChannelConfig(ADC3, ADC_Channel_12, 1, ADC_SampleTime_3Cycles);
  ADC_DMARequestAfterLastTransferCmd(ADC3, ENABLE);
  ADC_DMACmd(ADC3, ENABLE);
  ADC_Cmd(ADC3, ENABLE);
}

void DAC_Ch2_RampConfig(void)
{
  DMA_InitTypeDef DMA_InitStructure;
  
  DMA_DeInit(DMA1_Stream5);
  DMA_InitStructure.DMA_Channel = DMA_Channel_7;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)DAC_DHR12R2_ADDRESS;
  DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)&Ramp12bit;
  DMA_InitStructure.DMA_DIR = DMA_DIR_MemoryToPeripheral;
  DMA_InitStructure.DMA_BufferSize = RAMP_LENGTH;
  DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
  DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
  DMA_InitStructure.DMA_Mode = DMA_Mode_Circular;
  DMA_InitStructure.DMA_Priority = DMA_Priority_High;
  DMA_InitStructure.DMA_FIFOMode = DMA_FIFOMode_Disable;
  DMA_InitStructure.DMA_FIFOThreshold = DMA_FIFOThreshold_HalfFull;
  DMA_InitStructure.DMA_MemoryBurst = DMA_MemoryBurst_Single;
  DMA_InitStructure.DMA_PeripheralBurst = DMA_PeripheralBurst_Single;
  DMA_Init(DMA1_Stream5, &DMA_InitStructure);

  DMA_Cmd(DMA1_Stream5, ENABLE);
  DAC_Cmd(DAC_Channel_2, ENABLE);
  DAC_DMACmd(DAC_Channel_2, ENABLE);
}

void DAC_Ch1_TriggerConfig(void)
{

  DMA_InitTypeDef DMA_InitStructure;
  
  DMA_DeInit(DMA1_Stream6);
  DMA_InitStructure.DMA_Channel = DMA_Channel_7;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = DAC_DHR12R1_ADDRESS;
  DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)&Trigger12bit;
  DMA_InitStructure.DMA_BufferSize = RAMP_LENGTH;
  DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
  DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
  DMA_InitStructure.DMA_DIR = DMA_DIR_MemoryToPeripheral;
  DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  DMA_InitStructure.DMA_Mode = DMA_Mode_Circular;
  DMA_InitStructure.DMA_Priority = DMA_Priority_Low;
  DMA_InitStructure.DMA_FIFOMode = DMA_FIFOMode_Disable;         
  DMA_InitStructure.DMA_FIFOThreshold = DMA_FIFOThreshold_HalfFull;
  DMA_InitStructure.DMA_MemoryBurst = DMA_MemoryBurst_Single;
  DMA_InitStructure.DMA_PeripheralBurst = DMA_PeripheralBurst_Single;
  DMA_Init(DMA1_Stream6, &DMA_InitStructure);    

  DMA_Cmd(DMA1_Stream6, ENABLE);
  DAC_Cmd(DAC_Channel_1, ENABLE);
  DAC_DMACmd(DAC_Channel_1, ENABLE);
}

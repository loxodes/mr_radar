// adapted from DAC_SignalsGeneration/stm32f4xx_it.c 
// COPYRIGHT 2011 STMicroelectronics
#include "stm32f4xx_it.h"
#include "stm32f4xx_conf.h"
#include "stm32f4_discovery.h"

extern __IO uint8_t KeyPressed;
void NMI_Handler(void)
{
}

void HardFault_Handler(void)
{
  /* Go to infinite loop when Hard Fault exception occurs */
  while (1)
  {
  }
}

void MemManage_Handler(void)
{
  /* Go to infinite loop when Memory Manage exception occurs */
  while (1)
  {
  }
}

void BusFault_Handler(void)
{
  /* Go to infinite loop when Bus Fault exception occurs */
  while (1)
  {
  }
}

void UsageFault_Handler(void)
{
  /* Go to infinite loop when Usage Fault exception occurs */
  while (1)
  {
  }
}

void SVC_Handler(void)
{
}

void DebugMon_Handler(void)
{
}

void PendSV_Handler(void)
{
}

void SysTick_Handler(void)
{
}

void EXTI0_IRQHandler(void)
{
  if(EXTI_GetITStatus(USER_BUTTON_EXTI_LINE) != RESET)
  { 
    /* Change the wave */
    KeyPressed = 0;
    
    /* Clear the Right Button EXTI line pending bit */
    EXTI_ClearITPendingBit(USER_BUTTON_EXTI_LINE);
  }
}

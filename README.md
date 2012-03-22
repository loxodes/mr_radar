**mr_radar**

mr_radar is an in development open hardware frequency modulated continuous wave radar.

It is a radar altimeter for remote control quad-rotor helicopters and UAVs.
Eventually, it may be capable of radar imaging.


One of the goals of this project is to be easily reproducible and inexpensive.
All of the microwave components are available online from manufacturers or resellers like DigiKey, Allied Electronics, or Mini-Circuits. I have avoided using expensive components like circulators or SAW delay lines, even though they sound like fun. No chips with exposed pads are used, it is possible to assemble the boards with a soldering iron. All of the printed circuit boards are intended for plain inexpensive FR4 (which means filtering is done using chip filters and lumped elements, not distributed elements) and could be purchased from inexpensive board houses such as seeedstudio or iteadstudio. (I have several spares of most boards, I am willing to mail them out in exchange for postage.)
Signal processing will be done on a STM32F4 microcontroller, the STM32F4-Discovery evaluation board is available for around twenty dollars. 

Several test boards have been created for this project:

* mr_radar_frogpond proved the VCO and preamplifier amplifier layout and schematic.
* mr_radar_platypus contains all the microwave components, and proved the mixer, splitter, and IF amplifier.
* mr_radar_patch_antenna proved the patch antenna layout (it matched ADS simulation!)
* mr_radar_sandbox did not work as expected, the through hole SMA connector did not perform well at 3.4 GHz (but the U.fl did!)
* mr_radar_trolley is an in-progress board with voltage regulators, a VCO driver amplifier, and a USB-USART chip
* mr_radar_sandcastle is an untested board to evaluate an alternate mixer, a power splitter, and a directional coupler.
* mr_radar_pulser is an untested pulsed RF source

Some software has been written for this project:

* stm32f4_dacramp_adcif contains the code for the STM32F4 to generate the VCO control signal and sample the IF, and some python code to grab data off the STM32F4 and test signal processing
* vco_correction is an attempt at a VCO non-linearity correction algorithm. It is untested on hardware (because it requires expensive delay lines)
* compression is an in-progress (class project for a data compression class) to do image compression on the radar images (on the microcontroller)


![mr_radar_platypus testing](https://github.com/loxodes/mr_radar/raw/master/mr_radar.jpg)

Board layout is done so using Cadsoft Eagle.

Diagrams are drawn using Dia.

Software is written in Matlab, Python, and C. 

Simulations are done in Agilent ADS and LTSpice.

Measurements (s-parameters, noise figure measurements) are available in data/ 

All work is under an MIT license, see LICENSE for details. If you have questions, feel free to contact me at kleinjt@ieee.org



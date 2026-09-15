# PPG-based-BGL-assessment
This data set contains a multisite photoplethysmography (PPG) recordings from 20 subjects who were not hospitalized during data collection. This data set is intended to support the development of approaches for blood glucose level (BGL) estimation by analyzing PPG signals. The data comprises PPG recordings obtained simultaneously from three anatomical sites: the forehead, earlobe, and finger.

## When using this resource, please cite the original publication:
S. Vasquez Salazar and E. J. Argüello-Prada, «PPG-based multisite glucose assessment dataset,» September 14st 2026. [Online]. Available: https://github.com/sanvsquezsz/PPG-based-multisite-glucose-assessment.

## Data Collection
The data were obtained on an outpatient basis, i.e., none of the individuals were hospitalized, and data collection was performed in a laboratory. Before the experiment, all participants were instructed to refrain from eating or drinking for at least 2 hours.

Upon arrival at the laboratory, each volunteer was comfortably seated in a chair with a backrest. A 5-min stabilization period was allowed for the participant's heart rate to stabilize. During this period, participants were instructed to remain quiet and motionless. After stabilization, PPG signals were simultaneously acquired from the forehead, earlobe, and finger for 2 min (120 s). These were sampled at 40 Hz (fs = 40 Hz).

Immediately after PPG acquisition, blood glucose level was measured using a GlucoQuick® Vital invasive glucometer (Diabetrics Healthcare S.A.S., Colombia). The reference BGL values ranged from 88 to 138 mg/dL, with a mean ± standard deviation of 107.40 ± 14.64 mg/dL.

## PPG acquisition system
The multisite PPG acquisition system consisted of three **MAX30102** sensors. A **TCA9548A I2C multiplexer** (Texas Instruments, Dallas, TX, USA) was used to enable simultaneous operation of the three sensors, since the MAX30102 sensors share the same I2C address.

The TCA9548A multiplexer was connected to an **Arduino UNO microcontroller**. The multiplexer sequentially switched between the three I2C channels, allowing the Arduino to read the PPG signal from each sensor and transmit the measurements to a Windows 10 PC through a serial connection. A MATLAB R2017b (The MathWorks Inc., Natick, MA, USA) script was developed to receive and store the three PPG waveforms for subsequent extraction and processing.

## Sensor placement
The three PPG sensors were adapted to provide a secure and stable attachment at the selected anatomical sites:

* **Forehead:** the MAX30102 sensor was sewn into a fitness headband, positioning the sensor window directly against the skin.
* **Earlobe:** the sensor was embedded in a Velcro strip wrapped around the ear. This configuration was designed to provide secure attachment while minimizing the compressive effects associated with conventional PPG ear clips.
* **Finger:** the sensor was placed inside a commercial adult finger pulse oximeter clamp (Nellcor™, model DS-100A, with the original electronic circuitry removed).

## Description of subjects
20 subjects participated in the study. All volunteers were fully informed about the experimental procedure and provided written informed consent. The study included healthy (n = 15), prediabetic (n = 1), and diabetic (n = 4) adults aged 18 years or older. The participants' ages ranged from 21 to 76 years, with a mean ± standard deviation of 40.04 ± 17.56 years. Participants were included regardless of ethnicity, race, or gender. The male-to-female ratio in the sample was 1:1

The demographic and reference information for each participant is provided in the MS Excel file, "[filename].xlsx", and is summarized as follows:
  - Record #: name of the record associated with each individual, 'PPG_subj_##" (where ## is the subject number).
  - Age: range between 21 - 76 years old.
  - Gender: Male or Female.
  - Category: participant category, defined as Non-diabetic, Prediabetic, or Diabetic (Type 2).
  - BGL: reference blood glucose level measured using the reference glucometer, expressed in mg/dL.
    
## Background of glucose classification


## Data Files
The dataset is distributed in three formats:
1. CSV (comma-separated-value) format
2. Matlab (r) format
### CSV Format

### Matlab (r) format

     
## Contributors
For more information about the dataset, please contact the autors at:  santiago.vasquez.salazar@correounivalle.edu.co and erick.arguello@unimilitar.edu.co.

## Conflicts of interest
The autors have no conflicts of interest to declare.
## References

## Files
Total uncompressed size: [] MB.
### Access the files


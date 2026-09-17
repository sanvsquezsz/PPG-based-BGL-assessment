# PPG-based-BGL-assessment
This data set contains a multisite photoplethysmography (PPG) recordings from 20 subjects who were not hospitalized during data collection. This data set is intended to support the development of approaches for blood glucose level (BGL) estimation by analyzing PPG signals. The data comprises PPG recordings obtained simultaneously from three anatomical sites: the forehead, earlobe, and finger.

## When using this resource, please cite the original publication:
S. Vasquez Salazar and E. J. Argüello-Prada, «PPG-based BGL assessment dataset,» September 14th 2026. [Online]. Available: https://github.com/sanvsquezsz/PPG-based-multisite-glucose-assessment.

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

The demographic and reference information for each participant is provided in the MS Excel file, "PPG_info_data.xlsx", and is summarized as follows:
  - Record #: name of the record associated with each individual, 'PPG_subj_##" (where ## is the subject number).
  - Gender: Male or Female.
  - Age: range between 21 - 76 years old.
  - Diagnosed: 'Y' for diagnosed, and 'N' for undiagnosed for any type of diabetes.
  - Type: participant category, defined as Non-diabetic, Prediabetic, or Diabetic (Type 2).
  - BGL: reference blood glucose level measured using the reference glucometer, expressed in mg/dL.
    
## Background of blood glucose and diabetes classification
Blood glucose level (BGL) represents the concentration of glucose in the blood and is an important biomarker for assessing glucose metabolism. Abnormal glucose regulation is associated with metabolic disorders, particularly prediabetes and diabetes mellitus. Diabetes mellitus comprises a group of metabolic disorders characterized by persistent hyperglycemia, and its diagnosis can be established using different laboratory criteria, including fasting plasma glucose (FPG), 2-h plasma glucose during an oral glucose tolerance test (OGTT), glycated hemoglobin (HbA1c), or random plasma glucose in individuals presenting with classic symptoms of hyperglycemia [1].

According to the 2026 Standards of Care in Diabetes from the American Diabetes Association (ADA), prediabetes can be identified by an HbA1c level of 5.7–6.4%, FPG of 100–125 mg/dL, or a 2-h plasma glucose value of 140–199 mg/dL during a 75-g OGTT. Diabetes is diagnosed when HbA1c is ≥6.5%, FPG is ≥126 mg/dL, or 2-h plasma glucose during an OGTT is ≥200 mg/dL. A random plasma glucose ≥200 mg/dL can also be diagnostic when accompanied by classic symptoms of hyperglycemia or hyperglycemic crisis [1].

The main diagnostic criteria are summarized in the following table:
| **Measurement** | **Normal** | **Prediabetes** | **Diabetes** |
|:---|:---:|:---:|:---:|
| **Fasting plasma glucose (mg/dL)** | <100 | 100–125 | ≥126 |
| **2-h plasma glucose during OGTT (mg/dL)** | <140 | 140–199 | ≥200 |
| **HbA1c (%)** | <5.7 | 5.7–6.4 | ≥6.5 |
| **Random plasma glucose (mg/dL)** | — | — | ≥200* |

\* Random plasma glucose ≥200 mg/dL is diagnostic in the presence of classic symptoms of hyperglycemia or hyperglycemic crisis.

Conventional blood glucose assessment requires an invasive blood sample, motivating the development of non-invasive approaches for glucose monitoring. PPG is an optical technique that measures changes in blood volume and can be acquired from sites such as the finger, earlobe, and forehead. Its potential for BGL estimation has therefore been investigated as an alternative to conventional measurements. In this context, the present dataset combines PPG recordings from these three sites with reference BGL measurements obtained using a commercial glucometer from individuals with and without a previous diagnosis of type 2 diabetes. Participants were instructed to refrain from eating or drinking for at least 2 h before the measurements; therefore, the recorded BGL values should not be interpreted as fasting glucose measurements for diagnostic purposes.

## Data Files
The dataset is distributed in two formats:
1. CSV (comma-separated-value) format
2. Matlab (r) format
   
### CSV Format
For CSV format files, two subfolders are provided within the dataset, PPG_csv and PPG_csv_info, which contain:

  - **PPG_csv:** Contains the **physiological signal data for each subject**, with the three PPG recordings organized into separate columns. Each file contains one row per sample, with the **timestamp and the PPG signals** acquired from the **forehead, earlobe, and finger**. The files are named 'PPG_subj_##.csv', where ## corresponds to the subject number. The structure of each file is:
  ```
  'Timestamp', 'PPG_Forehead', 'PPG_Earlobe', 'PPG_Finger'
  ```
  - **PPG_csv_info:** Contains the **participant information and the corresponding PPG signals**. Each subject is represented by three rows, one for each recording location: forehead, earlobe, and finger. The first eight columns contain the subject and recording information, while the remaining columns contain the PPG signal samples. The files are named 'PPG_subj_wInfo_##.csv', where ## corresponds to the subject number. The **Location field** identifies the PPG recording site (Forehead, Earlobe, or Finger), while **fs** denotes the sampling frequency and **BGL** corresponds to the blood glucose level in mg/dL. No timestamp is included in these files. The structure of each file is:
  ```
  'ID', 'Age', 'Gender', 'Diagnosed', 'DiabetesStatus', 'BGL', 'fs', 'Location', 'Signal' ...
  ``` 

### Matlab (r) format

The *PPG_dataset.mat* file contains the following subset of the dataset in a single Matlab (r) variable named *data*. Each subject is organized as an element of a structure array containing participant information and the three PPG recordings. For each subject, the following information is provided:
  - **info:** A structure containing the participant-related information, including ID, Age, Gender, Diagnosed, DiabetesStatus, and BGL.
  - **PPG1:** A structure containing the PPG signal acquired from the forehead. The *signal* field contains the signal samples, *timestamp* contains the corresponding time values, *fs* contains the sampling frequency, and *Location* identifies the recording site.
  - **PPG2:** A structure containing the PPG signal acquired from the earlobe, with the same fields as PPG1.
  - **PPG3:** A structure containing the PPG signal acquired from the finger, with the same fields as PPG1.

The general organization of the MATLAB® structure is:
```text
data
├── info
│   ├── id
│   ├── Age
│   ├── Gender
│   ├── Diagnosed
│   ├── DiabetesStatus
│   └── BGL
│
├── PPG1
│   ├── signal
│   ├── timestamp
│   ├── fs
│   └── Location
│
├── PPG2
│   ├── signal
│   ├── timestamp
│   ├── fs
│   └── Location
│
└── PPG3
    ├── signal
    ├── timestamp
    ├── fs
    └── Location
```
## Contributors
For more information about the dataset, please contact the autors at:  kathalinao2602@gmail.com, erick.arguello@unimilitar.edu.co and santiago.vasquez.salazar@correounivalle.edu.co.

## Conflicts of interest
The autors have no conflicts of interest to declare.

## References
1. American Diabetes Association Professional Practice Committee for Diabetes (2026). 2. Diagnosis and classification of diabetes: Standards of Care in Diabetes—2026. Diabetes Care, 49(Supplement_1), S27–S49. https://doi.org/10.2337/dc26-S002

## Files
Total uncompressed size: 10.8 MB.
### Access the files
- [Download the ZIP file](https://github.com/sanvsquezsz/PPG-based-BGL-assessment/archive/refs/heads/main.zip) (4.3 MB)


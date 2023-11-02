## Water Tank TPS Comparison Tool

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2018, University of Wisconsin Board of Regents

## Description

The Water Tank TPS Comparison Tool is a standalone GUI written in MATLAB&reg; that can be used to compare radiotherapy water tank scan data to DICOM RT Dose volumes exported from the treatment planning system, such as during AAPM MPPG 5.b validation:

Geurts MW, Jacqmin DJ, Jones LE, Kry SF, Mihailidis DN, Ohrt JD, Ritter T, Smilowitz JB, Wingreen NE. [AAPM MEDICAL PHYSICS PRACTICE GUIDELINE 5.b: Commissioning and QA of treatment planning dose calculations-Megavoltage photon and electron beams](https://doi.org/10.1002/acm2.13641). J Appl Clin Med Phys. 2022 Sep;23(9):e13641. doi: 10.1002/acm2.13641. Epub 2022 Aug 10. PMID: 35950259; PMCID: PMC9512346.

## Installation

To install this application without MATLAB, download the compiled installer from the [Releases](https://github.com/mwgeurts/water_tank/releases) page. To install this function as a MATLAB App, download and install the file `WaterTankAnalysisTool.mlappsinstall` from this repository. If downloading the repository via git to run natively within MATLAB, make sure to download all submodules by running `git clone --recursive https://github.com/mwgeurts/water_tank`.

Once installed and launched, the tool will prompt you to select a directory containing the reference DICOM RT DOSE files. The files must be stored in the following folder and file naming scheme, where machine name, energy, and SSD are subfolders within the selected reference folder (examples are provided in parentheses). The tool will use the folder and filenames names to auto-match loaded scan profiles to the correct reference dataset.

```
Reference Folder
  -> Machine Name (TrueBeam)
    -> Energy (6 MV)
      -> SSD (100 cm)
        -> Field Size.dcm (10x10.dcm)
```

If you don't want the application to prompt you for the reference folder each time it launches, specify the reference folder in the config file on the reference `REFERENCE_PATH` line.

## Usage and Documentation

Once installed, execute `WaterTankAnalysis` to launch the GUI, select the folder containing the reference files, then select the corresponding water tank scan data file type from the dropdown menu and click `Browse`. The tool includes basic processing steps including shifting data for effective point of measurement, centering, smoothing, normalization, detector convolution, and converting depth-ionization to depth-dose curves. A Gamma evaluation can be applied to compare the measured to reference profiles. See the [wiki](../../wiki) for more information on the processing and data analysis features.

## License

Released under the GNU GPL v3.0 License. See the [LICENSE](LICENSE) file for further details. MATLAB is a registered trademark of MathWorks Inc. 

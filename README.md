## Water Tank Analysis Tool

by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2017, University of Wisconsin Board of Regents

## Description

The Water Tank Analysis Tool is a standalone GUI written in MATLAB&reg; that can be used
to compare radiotherapy water tank scan data to DICOM RT Dose volumes exported from the 
treatment planning system. The tool includes basic processing steps including shifting 
data for effective point of measurement, centering, smoothing, normalization, detector 
convolution, and converting depth-ionization to depth-dose curves. A Gamma evaluation 
can be applied to compare the measured to reference profiles. MATLAB is a registered 
trademark of MathWorks Inc. 

## Installation

To install this function as a MATLAB App, download and install the file 
`WaterTankAnalysisTool.mlappsinstall` from this repository. If downloading the repository 
via git, make sure to download all submodules by running 
`git clone --recursive https://github.com/mwgeurts/water_tank`.

Once installed, edit the config file `REFERENCE_PATH` option to point the tool to a folder
containing DICOM RT DOSE files exported from the treatment planning system. The files 
must be stored in the following folder and file naming scheme. The tool will use the 
machine, energy, SSD, and field size to auto-match loaded scan profiles to the correct 
reference dataset.

```
Machine Name
  -> Energy
    -> SSD
      -> Field Size.dcm
```

## Usage and Documentation

Once installed, execute `WaterTankAnalysis` to launch the GUI, then select the appropriate
scan data file type from the dropdown menu and click `Browse`. See the [wiki](../../wiki) 
for more information on the processing and data analysis features.

## License

Released under the GNU GPL v3.0 License. See the [LICENSE](LICENSE) file for further 
details.

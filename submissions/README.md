# Courseware submissions

Place the ZIP file for each completed experiment in this directory.

Use this naming format:

```text
DSD_Lab_NN_studentid1_name1_lastname1_studentid2_name2_lastname2_....zip
```

For example:

```text
DSD_Lab_01_401110918_Pourya_Erfanzadeh_402105802_Fatima_Timarchi_402106145_Ayeh_Saberi.zip
```

Rename the report inside the archive using this format:

```text
Report_DSD_Lab_NN_studentid1_name1_lastname1_studentid2_name2_lastname2_....pdf
```

For example:

```text
Report_DSD_Lab_01_401110918_Pourya_Erfanzadeh_402105802_Fatima_Timarchi_402106145_Ayeh_Saberi.pdf
```

Before uploading:

1. Open the experiment's `main.pdf` and verify the final report.
2. Rename the final report using the format above, then add it, the
   essential Quartus/ModelSim project and source files, and the LaTeX
   sources to the ZIP.
3. Rename the ZIP using the format above and place it here.
4. Upload the ZIP whose lab number matches the courseware assignment.

Include project descriptors and source files such as `.qpf`, `.qsf`, `.mpf`,
`.v`, `.bdf`, `.bsf`, `.sdc`, and `.vwf`. Do not include backup files,
compilation databases, output reports, simulation work libraries, wave logs,
or other generated files (including LaTeX build artifacts such as `.aux`,
`.log`, `.out`, `.fls`, and `.xdv`).

Also include the LaTeX sources so the TA can rebuild the PDF. Because
`main.tex` loads the shared style and fonts through relative paths, mirror
the repository layout inside a `LaTeX/` folder:

```text
LaTeX/report/main.tex
LaTeX/report/screenshots/
LaTeX/latex/dsdlab-report.sty
LaTeX/fonts/
```

Copy only the image directories the document actually references; the empty
`figures/` directory is not needed. Verify the bundle by running
`xelatex main.tex` inside `LaTeX/report/` before uploading.

Generated files in this directory are intentionally ignored by Git. Only this
README is tracked.

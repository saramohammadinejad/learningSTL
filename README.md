# learningSTL
Interpretable Classification of Time-Series Data using Eﬀicient Enumerative Techniques

This directory contains code to recreate the examples from

Sara Mohammadinejad, Jyotirmoy V. Deshmukh, Aniruddh G. Puranic, Marcell Vazquez-Chanlatte, Alexandre Donzé, "Interpretable Classification of Time-Series Data using Efficient Enumerative Techniques," in Hybrid Systems Computational & Control, ACM (2020).

----------------------------------------------------------------------------------------

There are four case studies in the paper. Each case generates the following results:

1) a STL formula
2) training time before optimization
3) training time after optimization 
4) mis-classification rate for train (train MCR)
5) mis-classification rate for test (test MCR)
6) a figure which shows various classes of traces in the experiment 

I will provide the instructions to obtain the results for each case study.

----------------------------------------------------------------------------------------

First, you should install the requirements. If you encountered any issues in this step, don't hesitate to send an email to saramoha@usc.edu.

Steps to install the requirements:

1) install Matlab R2018B with Simulink and Communications toolbox
2) install breach tool box which is provided as breach-master in RE_HSCC folder

* hint: there were a few bugs in the original breach toolbox the I resolved in breach-master folder. If you download and install breach from https://github.com/decyphir/breach,
You might get some errors. Hence, I highly recommend installing the provided breach-master folder in RE_HSCC folder. 

How to install breach:
1) breach requires a C/C++ compiler. For windows 64 bits, You can install the freely available MinGW-w64 C/C++ compiler in Matlab add -ons. For Mac, you need to install Xcode. More info can be found here: https://www.mathworks.com/support/requirements/supported-compilers.html. You can use mex -setup command to set up the compiler.

2) Matlab home -> environment section -> set path -> add folder -> choose breach-master folder -> save -> close

3) Type InstallBreach in Matlab command window


When installation is done, you can run main codes in provided folders to see the results and figures provided in the paper:

----------------------------------------------------------------------------------------
* go to "/RE_HSCC/experiments/Maritime_surveillance/" directory

steps to run: 

1) open main_green1.m
2) Modify cd (change directory) commands in the code (lines 10 and 15) based on your platform. Line 10 should point to "/RE_HSCC/experiments/Maritime_surveillance/data", and line 15 should point to "/RE_HSCC/EnumerativeSolver".
3) run main_green1.m
4) you will see figure 4 and some of the results reported in the description of " Maritime surveillance case study" in Matlab command window.(hint1: the reported execution time might be different due to using a different platform hint2: this code takes a long time to run (around 1 hours))

5) Do the above steps for main_green2.m

6) open main_red.m
7) edit cd commands exactly the same as step 2
8) run main_red.m
9) you will see some of the results reported in the description of " Maritime surveillance case study" in Matlab command window. (hint: the reported execution time might be different due to using a different platform)

10) open main_blue.m
11) edit cd commands exactly the same as step 2
12) you will see some of the results reported in the description of " Maritime surveillance case study" in Matlab command window.(hint: the reported execution time might be different due to using a different platform)

----------------------------------------------------------------------------------------
* go to "/RE_HSCC/experiments/linear_system/" directory

steps to run: 

1) open main.m
2) Modify cd (change directory) command in the code (line40) based on your platform. It should point to "/RE_HSCC/EnumerativeSolver".
3) run main.m
4) you will see figure 5 and the results reported in the description of "linear systems case study" in Matlab command window. I highlighted the results in the paper.pdf (hint: the reported execution time might be different due to using a different platform)

---------------------------------------------------------------------------------------
* go to "/RE_HSCC/experiments/cruise_control_train/" directory

steps to run: 

1) open /RE_HSCC/experiments/cruise_control_train/main.m
2) Modify cd (change directory) command in the code (line81) based on your platform. It should point to "/RE_HSCC/EnumerativeSolver".
3) run main.m
4) you will see figure 6 and the results reported in the description of "cruise control of train case study" in Matlab command window. (hint: the reported execution time might be different due to using a different platform)

---------------------------------------------------------------------------------------
* go to "/RE_HSCC/experiments/PID_controller/" directory

steps to run: 

1) open /RE_HSCC/experiments/PID_controller/main.m
2) Modify cd (change directory) command in the code (line12) based on your platform. It should point to "/RE_HSCC/EnumerativeSolver".
3) run main.m
4) you will see figure 7 and the results reported in the description of "PID controller case study" in Matlab command window. (hint: the reported execution time might be different due to using a different platform)

---------------------------------------------------------------------------------------

Final hints:

1) Figure 3 is a synthetic example drawn in powerpoint to explain a technique from a previous work. That's why I didn't provide instruction to reproduce it. Figure 1 and 2 takes a long time to generate (around 1 day). Based on discussions we had with RE PC, long execution time is a problem to check reproducibility. That's why we didn't provide instructions to reproduce those figures. 

2) Data reported in table1 is a summary of results obtained in above case studies (that I provided instructions to run each of them individually). That's why I didn't provide instruction to reproduce it again.


Questions and bug reports (and any examples of the use of this technique on other problems) can be send to saramoha@usc.edu.

Sara Mohammadinejad 
January 2020
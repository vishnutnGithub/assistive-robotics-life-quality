# assistive-robotics-life-quality
Study of assistive robotics for improving human life quality.

Wearable Wrist Rehabilitation Using Dual-Channel Functional Electrical Stimulation (FES)

📌 Overview

This project presents a lightweight, wearable wrist rehabilitation system that restores wrist pronation and supination using dual-channel Functional Electrical Stimulation (FES) — stimulating the user's own forearm muscles instead of relying on motors, pneumatics, or series elastic actuators. The system targets a wrist-rotation gap identified across existing haptic-glove rehabilitation literature, which consistently focuses on finger-level movement.

🚀 Features


Dual-channel FES: separate grip (ch1) and rotation (ch2) stimulation channels
Voluntary-first, assist-as-needed control logic — FES only activates if the patient's own voluntary movement falls short of the target
Escalating FES force profile (1 N → 10 N in 1 N / 0.5 s steps) with a safety ceiling
Grip-then-rotate task modelling (e.g. opening a bottle)
LED status feedback: blue (prompt), red (attempting), solid green (voluntary success), blinking green (FES-assisted success)
Behavioural, software-only simulation of the full controller logic (MATLAB), validated across five simulated patients before any hardware is built
Actuator-free design — eliminates mechanical actuators entirely, targeting the pronator/supinator muscle groups directly


🧠 System Components


Microcontroller (stimulation control logic, dual-channel FES driver)
Forearm-mounted dual-channel FES module (grip channel + rotation channel electrodes)
Fabric glove (grip interface, sensing mount)
Grip sensing (FSR — normalised 0–1 grip signal, threshold-based)
Rotation sensing (angle/orientation sensing for wrist supination, target 60°)
LED status indicator (blue / red / solid green / blinking green)
Portable, battery-powered wearable hub


🛠️ Design

The system is divided into:


Power section — portable, battery-powered wearable hub (targeting a fully untethered, home-usable device)
Interface section — fabric glove + forearm-mounted FES band, under 150 g total mass
Logic section — microcontroller running the dual-channel stimulation controller: voluntary-movement monitoring, threshold checks, escalating FES force logic, and LED state machine


📊 Project Status

🔧 Research case study — literature review, system design, and behavioural simulation stage

✅ Completed:


Literature review of 8 sources on haptic-glove hand/wrist rehabilitation, with a wrist-rotation research gap identified
Proposed dual-channel FES system design, compared against traditional mechanical rehabilitation baselines (motors, pneumatics, SEAs)
Behavioural, software-only simulation of the grip-then-rotate controller logic (MATLAB), including the escalating FES force profile and LED state machine
Controller refinement identified during simulation (voluntary-term leak causing achieved position to drift after success — see Section 6.6 of the final report)


🚧 Future scope :


Physical dual-channel FES hardware and electrode placement
Wearable glove and forearm-band fabrication
User-specific calibration procedure
AI-based adaptive stimulation
Clinical validation with real patients
Companion mobile app


👥 Team


Vishnu Thaimachedath Nandakumar

Jeethu Thambi

Thadepalli Nikitha



2/12/26, 11:41 PM                                            testbed_setup_main
  Testbed Setup Guide
  Last Updated: 1/11/2026
  Summary: This document provides a step-by-step guide to setting up a controlled cybersecurity
  testbed using VirtualBox (for Windows/Linux) or UTM (for macOS). The testbed consists of three virtual
  machines (Kali Attack VM, Kali Defense VM, and Metasploitable-2 Target VM) designed to emulate
  real-world attack and defense scenarios.
  Table of Contents
  Testbed Architecture and Purpose
  Setup for Windows/Linux (VirtualBox)
  Setup Guide for macOS (UTM on Intel/x86_64 Macs)
  Setup Guide for macOS (UTM on Apple Silicon / ARM64 Macs)
  Verifying Correct Setup (Linux/macOS/Windows)
  Quick Tutorial on VirtualBox Network Modes
  Helpful Resources for Testbed Setup
2/12/26, 11:41 PM                                                testbed_setup_main
  Testbed Architecture and Purpose
                                      +---------------------+
                                      |    Host Machine        |
                                      |    (VirtualBox)        |
                                      +---------------------+
                                                    |
                                   +---------------------+
                                   | Host-Only Network        |
                                   |    (192.168.10.x)        |
                                   +---------------------+
                                     /              |        \
                                   /                |         \
              +----------------+           +----------------+     +----------------+
              |    Kali Attack        |    |    Kali Defense  |   |      MS-2 Target |
              |         VM            |    |          VM      |   |         VM       |
              |    192.168.10.11 |         |    192.168.10.12 |   |   192.168.10.13 |
              +----------------+           +----------------+     +----------------+
                          |                           |
                          +------------------+
                                     |
                       +---------------------+
                       | NAT/Bridged Adapter |
                       | (via Host Machine)            |
                       |   (Internet Access)           |
                       +---------------------+
  The above figure visually illustrates the current testbed setup, focused mainly on Linux/Windows
  scenario but UTM testbed setup is similar. The figure shows all three VMs, Kali Attack, Kali Defense, and
  MS-2 Target, connected within the same subnet through a Host-Only (private and isolated) Network. It
  also highlights the optional NAT adapter configuration for internet access via the host machine.
  Important Note: You may use any virtualization environment (e.g., VMware Workstation, VirtualBox,
  UTM, or others). As long as you can successfully set up the three virtual machines and complete all
  hands-on assignments, your choice of platform is acceptable.
  Virtual Machines and Their Roles
      1. Kali Attack VM:
               Role: The Kali Attack VM is the primary machine for simulating offensive cybersecurity
               operations. It is equipped with a wide range of pre-installed tools for penetration testing,
2/12/26, 11:41 PM                                              testbed_setup_main
               vulnerability scanning, and exploitation. This VM acts as the attacker in the testbed, generating
               network traffic to simulate real-world cyberattacks.
               Key Tools:
                     Nmap: For network scanning and reconnaissance.
                     Metasploit Framework: For exploiting vulnerabilities in the target system.
                     Wireshark: To analyze network traffic from an attacker's perspective.
               Purpose: By using this VM, students will understand the mindset and methodologies of
               attackers. It will help them learn how vulnerabilities are exploited, how to identify potential
               attack vectors, and how to execute common offensive security techniques.
      2. Kali Defense VM:
               Role: The Kali Defense VM serves as the defensive counterpart, used to monitor, sniff, and
               analyze the network for malicious activity. This VM demonstrates how to defend against
               attacks, detect intrusions, and analyze threats.
               Key Tools:
                     Snort: For intrusion detection and prevention.
                     Wireshark: To analyze network packets for anomalies.
                     tcpdump: For capturing and analyzing raw traffic at the command-line level.
               Purpose: This VM provides students with insight into defensive security operations. It will
               enable them to practice creating detection signatures, analyzing attack patterns, and
               responding to threats. Understanding defense is crucial for building robust cybersecurity
               strategies.
      3. MS-2 Target VM:
               Role: The Metasploitable-2 Target VM is a deliberately vulnerable system designed to
               simulate real-world security flaws. It contains a variety of outdated and misconfigured services,
               making it an ideal target for learning offensive techniques.
               Key Features:
                     Vulnerabilities in web servers, databases, and operating system services.
                     Misconfigurations that allow for SQL injection, command injection, and buffer overflow
                     attacks.
               Purpose: This VM serves as a "sandbox" for students to practice and validate offensive
               techniques in a controlled environment. It allows for safe experimentation with exploits and
               fosters an understanding of how vulnerable systems behave under attack.
  Testbed Architecture and Network Configuration
      1. Host-Only Adapter Network:
               Reasoning: A host-only network isolates the testbed from external networks, including the
               internet. This ensures:
2/12/26, 11:41 PM                                              testbed_setup_main
                     Security: Prevents unintended network traffic or exploitation outside the testbed.
                     Control: Allows students to focus on the interaction between the testbed machines without
                     interference.
                     Simplicity: Provides a controlled environment for simulating attacks and defenses.
               Configuration:
                     All VMs are assigned IP addresses within the same subnet, enabling seamless
                     communication and testing.
                     The host machine acts as the gateway, allowing monitoring or intervention if necessary.
      2. Interconnection:
               The Kali Attack VM generates traffic aimed at exploiting vulnerabilities in the MS-2 Target VM.
               The Kali Defense VM monitors this traffic, detecting attack patterns, analyzing logs, and
               observing system behavior.
               Students will be able to observe both offensive and defensive actions simultaneously, providing
               a comprehensive understanding of the cybersecurity lifecycle.
  Testbed Educational Objectives
      1. Offensive Security:
               Understand how attackers exploit system vulnerabilities.
               Practice using tools and techniques for reconnaissance, scanning, and exploitation.
               Develop an attacker’s perspective, enhancing the ability to predict potential security threats.
      2. Defensive Security:
               Learn how to monitor and analyze network traffic for suspicious behavior.
               Practice creating intrusion detection rules and analyzing attack patterns.
               Understand how to mitigate vulnerabilities and prevent exploitation.
      3. Comprehensive View:
               By interacting with all three machines in the testbed, students gain a holistic understanding of
               the attack-defense relationship.
               The testbed bridges the gap between theoretical knowledge and practical application, preparing
               students for real-world cybersecurity challenges.
  Why This Testbed is Essential
  This three-VM architecture reflects real-world scenarios where organizations face constant threats from
  attackers and must implement robust defenses. By working with this testbed, students will:
         Develop technical skills in both offensive and defensive security.
         Understand the lifecycle of a cyberattack, from reconnaissance to exploitation and defense.
         Gain hands-on experience with industry-standard tools and techniques.
         Learn how attackers think, enabling them to build better defenses.
2/12/26, 11:41 PM                                            testbed_setup_main
  Minimum and Recommended VM Specifications
       Component                          Minimum                       Recommended           Optimal
                           Windows 10 / macOS 10.15 /           Windows 11 / macOS 12+ /
     OS                                                                                    Latest OS
                           Ubuntu 20.04+                        Latest Linux
                           Quad-core with hyper-threading       6-core+ (e.g., Intel i7 /  High-end
     CPU
                           (e.g., Intel i5 / Ryzen 3)           Ryzen 5)                   multi-core
     RAM                   8 GB                                 16 GB                      32 GB
     Storage               120 GB free                          250 GB SSD                 500 GB+ SSD
                           VT-x / AMD-V enabled in
     Virtualization                                             Required                   Required
                           BIOS/UEFI
  🔧 Component Breakdown:
  1. Operating System
         Minimum: Windows 10 (64-bit), macOS 10.15+, or Linux (e.g., Ubuntu 20.04+)
         Recommended: Windows 11, macOS 12+, or latest stable Linux distributions
         Requirement: Must support and have hardware virtualization (VT-x or AMD-V) enabled in
         BIOS/UEFI
  2. CPU (Processor)
         Minimum: Quad-core with hyper-threading (e.g., Intel Core i5 / AMD Ryzen 3)
         Recommended: 6-core or better (e.g., Intel Core i7 / AMD Ryzen 5) to run multiple VMs efficiently
  3. RAM (Memory)
         Minimum: 8 GB (usable but limited for multitasking)
         Recommended: 16 GB (smooth performance with multiple VMs)
         Optimal: 32 GB (for heavy multitasking, snapshots, and resource-intensive labs)
2/12/26, 11:41 PM                                            testbed_setup_main
  4. Storage (Disk Space)
         Minimum: 120 GB free
         Recommended: 250 GB+ SSD for speed and space
               Suggested allocation:
                     Kali Attack VM: ~40 GB
                     Kali Defense VM: ~40 GB
                     MS-2 Target VM: ~20 GB
                     Snapshots, Logs, Tools: ~50 GB+
         Optimal: 500 GB+ SSD for best performance with VM snapshots and concurrent environments
      5. Virtualization Support:
               Ensure hardware virtualization is enabled in the system BIOS/UEFI settings.
  Setup for Windows/Linux (VirtualBox)
  Step 1: Download and Install VirtualBox
      1. Download VirtualBox (Windows/Linux hosts)
               Download the latest VirtualBox 7.x for your host OS from the official site. (VirtualBox)
      2. Install VirtualBox
               Run the installer and keep defaults unless you have a constraint (corporate endpoint policies,
               limited disk, etc.).
               Linux: you may install via your distro packages or Oracle’s repository (either is fine; follow your
               environment’s standard).
      3. Install the matching Extension Pack (recommended)
               Download the Extension Pack that matches your VirtualBox version (USB support, etc.).
               (VirtualBox)
      4. Verify installation
               Launch VirtualBox and confirm it opens without errors.
       Windows 11 Host Notes (only if you have problems):
       VirtualBox may be slowed down or fail to start if Windows 11 is using Hyper-V / VBS features.
       Symptoms include “VT-x is not available”, very poor VM performance, or missing 32-bit guest
       options. If this happens:
2/12/26, 11:41 PM                                            testbed_setup_main
            Confirm Intel VT-x / AMD-V is enabled in BIOS/UEFI.
            In Windows Features, consider disabling Hyper-V, Windows Hypervisor Platform, and
            Virtual Machine Platform (may affect WSL2).
            If needed, temporarily disable Core isolation → Memory integrity.
            See: VirtualBox Forums for common Windows 11 host fixes.
       Optional (Windows 11 guest installs only): If you are installing Windows 11 as a guest VM
       inside VirtualBox, this video may help:
       https://www.youtube.com/watch?v=aWYW7BcSqzo&t=1
  Step 2: Kali VMs Setup (Attack and Defense)
  2.1. Download and Import Kali Linux Virtual Machine
      1. Download the pre-built Kali VirtualBox image (x86_64/amd64)
               Go to Kali’s Virtual Machines page → VirtualBox Images. (Kali Linux)
               Download the latest .7z (example naming pattern:
                kali-linux-YYYY.x-virtualbox-amd64.7z ).
      2. Extract the archive
               Windows: 7-Zip
               Linux: p7zip
               You should see a .vbox file and a .vdi disk.
      3. (Optional) Verify integrity
               Compare your SHA256 hash to the value on the Kali download page:
                 sha256sum kali-linux-*-virtualbox-amd64.7z
  2.2. Import and Configure the Kali VMs
      1. Add the VM to VirtualBox
               VirtualBox → Machine → Add… → select the extracted .vbox file.
               Rename to Kali Attack VM (recommended).
      2. Adjust VM resource settings (recommended baseline)
               RAM: 4096 MB
               CPU: 2 cores
2/12/26, 11:41 PM                                               testbed_setup_main
               Confirm the attached disk is the expected .vdi .
      3. Create the Defense VM by cloning
               Right-click Kali Attack VM → Clone
               Name: Kali Defense VM
               Choose Full Clone
               Generate new MAC addresses for all network adapters (required).
      4. Start and log in
               Default credentials for Kali pre-built VM images are typically:
                     Username: kali
                     Password: kali (Kali Linux)
       Note: Kali’s “default credentials” guidance applies to pre-created images / VM images; ISO installs
       will prompt you to create credentials. (Kali Linux)
  Step 3: MS-2 Target VM Installation and Configuration
  in VirtualBox
  Metasploitable-2 is intentionally vulnerable; keep it isolated (Host-Only) unless your lab explicitly
  requires otherwise. (Rapid7 Docs)
  3.1. Download and Extract the MS-2 Target VM
      1. Download Metasploitable-2 from SourceForge. (SourceForge)
      2. Extract the .zip and locate the disk file (commonly Metasploitable.vmdk ).
  3.2. Create a New Virtual Machine in VirtualBox
      1. VirtualBox → New
      2. Name: MS-2 Target VM
      3. Type: Linux
      4. Version: Ubuntu (32-bit) (or Other Linux (32-bit) if Ubuntu 32-bit is not listed)
               If you do not see 32-bit options, it is usually a host virtualization configuration issue (see
               Windows 11 quick checks above).
      5. Memory: 512 MB (minimum) to 1 GB (recommended)
      6. Hard disk: Use an existing virtual hard disk file → select Metasploitable.vmdk
2/12/26, 11:41 PM                                            testbed_setup_main
  3.3. Adjust VM Settings
          System → Processor: 1 core (2 optional)
          Display: 16 MB+ video memory
          Network:
               Adapter 1: Host-Only Adapter (required)
               Adapter 2: Off (recommended for safety; only enable NAT if the lab explicitly requires it)
  3.4. Start and Verify the MS-2 Target VM
          Login defaults: msfadmin / msfadmin (SourceForge)
          Basic checks:
            uname -a
            ifconfig
  Step 4: Configure Network Settings
  4.1. VirtualBox Host-Only Network Setup
      1. Open the network manager:
               VirtualBox 7.x: File → Tools → Network Manager (or similar “Host Network Manager” entry).
      2. Create (or select) a Host-Only network and set:
               IPv4 Address: 192.168.10.1
               Subnet Mask: 255.255.255.0
      3. DHCP (recommended for simplicity)
               Enable DHCP and use a range such as:
                     Server: 192.168.10.100
                     Lower: 192.168.10.101
                     Upper: 192.168.10.254
       If you want fixed addresses exactly matching your diagram (…11, …12, …13), use static IPs
       inside each VM or DHCP reservations (static addressing is usually more predictable for labs).
  4.2. Attach VMs to the Host-Only Network
  For each VM: Settings → Network
2/12/26, 11:41 PM                                            testbed_setup_main
      1. Adapter 1
               Enable Network Adapter
               Attached to: Host-Only Adapter
               Name: select your host-only network (e.g., vboxnet0 )
      2. Adapter 2 (optional Internet access for Kali only)
               Kali Attack/Defense: enable Adapter 2 → NAT (only if you need updates/tools)
               MS-2 Target: keep Adapter 2 disabled
  Setup Guide for macOS (UTM on
  Intel/x86_64 Macs)
  This section explains how to configure the testbed on Intel macOS using UTM (QEMU), including Kali
  Attack VM, Kali Defense VM, and Metasploitable-2 Target VM.
       Recommended isolation approach: Use Host Network for the private lab subnet, and optionally
       add Shared Network (NAT) as a second NIC for internet access. Host Network provides isolation
       but does not provide DHCP, so you must assign static IPs. (UTM Documentation)
  Step 1: Install UTM
      1. Install UTM for macOS (from the official UTM distribution).
      2. Launch UTM once to confirm it opens correctly.
  Reference (official): (UTM Documentation)
  Step 2: Install Homebrew utilities (optional, for disk conversion
  tools)
  UTM includes the virtualization runtime, but it can be convenient to install command-line tools (e.g.,
   qemu-img ) for converting disks.
2/12/26, 11:41 PM                                            testbed_setup_main
     xcode-select --install
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/instal
     brew install qemu p7zip
  Step 3: Download and prepare VM images
  Download pages (copy/paste):
     Kali prebuilt VMs: https://www.kali.org/get-kali/#kali-virtual-machines
     Metasploitable-2:           https://sourceforge.net/projects/metasploitable/files/Metasploitable2/
  3.1: Kali Linux (x86_64)
      1. Download the VirtualBox (amd64/x86_64) image archive ( .7z ) for Kali.
      2. Extract it (GUI extractor, or 7z ):
     7z x kali-linux-XXXX-virtualbox-amd64.7z
  You should see a .vdi disk (and possibly a .vbox metadata file). UTM can typically use the disk
  directly.
  3.2: Metasploitable-2
      1. Download and unzip Metasploitable-2; locate the .vmdk disk.
      2. Option A (recommended): convert to qcow2:
     qemu-img convert -O qcow2 Metasploitable.vmdk metasploitable.qcow2
   qemu-img is the standard tool for disk conversion. (GitLab)
  Step 4: Create VMs in UTM
  Repeat for all three VMs (two Kali VMs + MS-2).
2/12/26, 11:41 PM                                            testbed_setup_main
  4.1: Create the VM
      1. UTM → + → choose Virtualize → Linux (Intel Mac can virtualize x86_64 Linux).
      2. Name the VM (e.g., Kali Attack VM , Kali Defense VM , MS-2 Target VM ).
  4.2: CPU and memory
         Kali Attack/Defense: 2 CPU, 4 GB RAM
         MS-2: 1 CPU, 1 GB RAM (512 MB may work but is slower)
  4.3: Disk
         Remove the default empty drive.
         Add Import Existing Drive:
               Kali: select the extracted .vdi
               MS-2: select metasploitable.qcow2 (or the .vmdk if you did not convert)
  4.4: Boot settings
         Keep defaults initially.
         If the VM drops into a UEFI shell or fails to find a boot disk, toggle the VM’s UEFI Boot option
         (some imported disks expect legacy BIOS; others boot fine with UEFI).
  Step 5: Configure networking (recommended: Host Network +
  optional Shared Network)
  UTM provides different network attachment modes (notably Shared (NAT) and Bridged). For a lab
  subnet isolated from the internet, use Host Network (created in UTM preferences). Host Network has
  no DHCP. (UTM Documentation)
  5.1: Create a Host Network in UTM
      1. UTM → Settings/Preferences → Network
      2. Create a Host Network (this is your private lab network)
  5.2: Attach NICs (per-VM)
  For each VM:
         NIC 1 (lab subnet): attach to your Host Network
2/12/26, 11:41 PM                                            testbed_setup_main
         NIC 2 (optional internet): add a second NIC set to Shared (NAT)
       Shared (NAT) provides outbound internet access; Bridged exposes the VM to your physical LAN.
       (UTM Documentation)
  Step 6: Assign IP addresses
  Because Host Network has no DHCP, set static IPs on the Host Network interface (NIC 1). (UTM
  Documentation)
  Use this addressing plan on NIC 1:
         Kali Attack: 192.168.10.11/24
         Kali Defense: 192.168.10.12/24
         MS-2: 192.168.10.13/24
  6.1: Kali (NetworkManager) — recommended
  On each Kali VM:
     sudo nmtui
         Edit the wired connection corresponding to NIC 1 / Host Network
         Set IPv4 configuration = Manual
         IP/netmask:
               Attack: 192.168.10.11/24
               Defense: 192.168.10.12/24
         Gateway: leave blank (Host Network is isolated)
         Save → Activate connection
  If you added NIC 2 (Shared/NAT), leave it on DHCP so Kali can reach the internet when needed.
  6.2: Metasploitable-2 (classic /etc/network/interfaces )
  Metasploitable-2 commonly uses /etc/network/interfaces :
     sudo nano /etc/network/interfaces
  Example:
2/12/26, 11:41 PM                                            testbed_setup_main
     auto eth0
     iface eth0 inet static
         address 192.168.10.13
         netmask 255.255.255.0
  Restart networking (method varies on MS-2; simplest is reboot):
     sudo reboot
  Step 7: Login credentials
         Kali: username kali , password kali (if using the official prebuilt VM image)
         Metasploitable-2: username msfadmin , password msfadmin
  Important notes
         Do not use Bridged unless you explicitly want the lab visible on your LAN; it reduces isolation and
         your gateway/IP settings will be dictated by your real network (DHCP/router), not 192.168.10.1 .
         (UTM Documentation)
         With Host Network, lack of DHCP is expected; static IPs are required. (UTM Documentation)
  Setup Guide for macOS (UTM on Apple
  Silicon / ARM64 Macs)
  This section explains how to configure the testbed on Apple Silicon macOS (M1/M2/M3) using UTM,
  including Kali Attack VM, Kali Defense VM, and the Metasploitable-2 Target VM.
       Recommended isolation approach: Use a Host Network for the private lab subnet, and
       optionally add Shared Network (NAT) as a second NIC for internet access. Host Network does
       not provide DHCP, so you must assign static IPs. (UTM Documentation)
       Note (important correction): On Apple Silicon, UTM supports more than “NAT and Bridged”
2/12/26, 11:41 PM                                            testbed_setup_main
       networking; UTM also supports Host Network / Host Only options on macOS. (UTM
       Documentation)
  Step 1: Metasploitable-2 (Emulated Setup)
  Metasploitable-2 is an x86 Linux VM, so on Apple Silicon it must run via emulation (slower, but
  acceptable for the victim role).
  1.1: Obtain and prepare the Metasploitable-2 disk
      1. Download and unzip Metasploitable-2; locate the .vmdk disk.
      2. Convert to qcow2 (recommended):
     qemu-img convert -O qcow2 Metasploitable.vmdk metasploitable.qcow2
   qemu-img is the standard tool for disk conversion. (GitLab)
  1.2: Create the MS-2 VM in UTM (Emulate)
      1. UTM → + → choose Emulate → Linux (or “Other” if needed).
      2. Name it MS-2 Target VM .
  If the wizard requires an ISO: attach any Linux ISO as a placeholder, then remove it after creation
  (UTM → VM Settings → Drives → remove the ISO) and keep only the Metasploitable disk.
  1.3: CPU, memory, and boot settings (MS-2)
         CPU: 1
         Memory: 1 GB (512 MB may work but is slower)
         Boot: MS-2 commonly expects legacy/BIOS-style boot; if it drops into a UEFI shell or fails to
         boot, disable UEFI Boot in the VM’s QEMU settings. (UTM Documentation)
2/12/26, 11:41 PM                                            testbed_setup_main
  1.4: Attach the disk
         VM Settings → Drives → Import Existing Drive → select metasploitable.qcow2 .
  Step 2: Kali Linux (ARM64 Setup)
  On Apple Silicon, Kali should be installed as an ARM64 guest (virtualized), rather than using prebuilt
  x86 VirtualBox images.
  1.1: Download a Kali ARM64 installer ISO
  Use the official Kali installer page and select the ARM64/Apple Silicon installer ISO. (Avoid pinning a
  specific version in the guide, since links change frequently.)
  1.2: Create the Kali VM in UTM (Virtualize)
      1. UTM → + → choose Virtualize → Linux.
      2. Select the downloaded ARM64 Kali installer ISO.
      3. Assign resources:
               CPU: 2
               Memory: 4096 MB
      4. Name the VM Kali Attack VM .
  Repeat for Kali Defense VM (you can either install twice or clone, if your UTM workflow supports it
  cleanly).
  1.3: Install Kali (and handle the “black screen” case if it appears)
  Start the VM and run the standard Kali installer.
  If the installer boots to a black screen, UTM’s documented workaround is to add a Serial device and
  perform installation in the terminal/serial view, then remove the serial device after installation. (UTM
  Documentation)
2/12/26, 11:41 PM                                            testbed_setup_main
  1.4: Post-installation (Kali)
      1. Remove the installer ISO: VM Settings → Drives → clear/remove the ISO.
      2. Boot into the installed system and confirm login.
  1.5: Configure networking (recommended: Host Network +
  optional Shared Network)
  UTM provides multiple macOS networking modes, including:
         Shared Network (NAT) (outbound internet access)
         Bridged (VM appears on your physical LAN)
         Host Only / Host Network (isolation-oriented modes) (UTM Documentation)
  1.5.1: Create a Host Network (private lab network)
      1. UTM → Settings/Preferences → Network
      2. Create a Host Network
  Reminder: Host Networks do not provide DHCP, so VMs must use static IPs. (UTM Documentation)
  1.5.2: Attach NICs (per VM)
  For each VM (Kali Attack, Kali Defense, MS-2):
         NIC 1 (lab subnet): attach to your Host Network
         NIC 2 (optional internet): add a second NIC set to Shared Network (NAT)
  1.6: Assign IP addresses
  Because Host Network has no DHCP, set static IPs on the Host Network interface (NIC 1). (UTM
  Documentation)
  Use this addressing plan on NIC 1:
         Kali Attack: 192.168.10.11/24
         Kali Defense: 192.168.10.12/24
         MS-2: 192.168.10.13/24
2/12/26, 11:41 PM                                            testbed_setup_main
  1.6.1: Kali (NetworkManager) — recommended
  On each Kali VM:
     sudo nmtui
         Edit the wired connection corresponding to NIC 1 / Host Network
         Set IPv4 configuration = Manual
         IP/netmask:
               Attack: 192.168.10.11/24
               Defense: 192.168.10.12/24
         Gateway: leave blank (Host Network is isolated)
         Save → Activate connection
  If you added NIC 2 (Shared/NAT), leave it on DHCP.
  1.6.2: Metasploitable-2 (classic /etc/network/interfaces )
     sudo nano /etc/network/interfaces
  Example:
     auto eth0
     iface eth0 inet static
         address 192.168.10.13
         netmask 255.255.255.0
  Restart networking (MS-2 varies; simplest is reboot):
     sudo reboot
  1.7: Login credentials
         Kali: the credentials you created during installation (use kali/kali only if you explicitly set it)
         Metasploitable-2: username msfadmin , password msfadmin
2/12/26, 11:41 PM                                              testbed_setup_main
  Key Differences Summary (Intel vs Apple Silicon)
                                       Intel / x86_64
              VM                                                          Apple Silicon / ARM64 (UTM)
                                    (UTM/VirtualBox)
                               Import VirtualBox image
     Kali VMs                                                Install from ARM64 installer ISO
                               ( .vdi )
     Metasploitable-
                               Virtualize with .vmdk         Emulate (x86), attach .qcow2 disk
     2
     UEFI (Kali)               Varies by imported disk       Keep defaults; adjust only if needed
     UEFI (MS-2)               Often disabled for MS-2       Disable if MS-2 fails to boot (common)
                               Host-only available in        Use Host Network (no DHCP) + optional
     Networking
                               VirtualBox                    Shared/NAT (UTM Documentation)
  Important Notes
         Host Network has no DHCP (static IPs are required). (UTM Documentation)
         Prefer Shared/NAT for internet access; use Bridged only if you explicitly want the lab visible on
         your LAN. (UTM Documentation)
         If Kali installer shows a black screen, use the Serial-device workaround described in UTM’s Kali
         guest guide. (UTM Documentation)
  Verifying Correct Setup
  (Linux/macOS/Windows)
  Regardless of the testbed setup (VirtualBox on Windows/Linux or UTM on macOS), follow these steps to
  ensure that your virtual machines are correctly configured and can communicate with each other.
  Step 1: Start All Virtual Machines
         Power on the Kali Attack VM, Kali Defense VM, and MS-2 Target VM.
2/12/26, 11:41 PM                                            testbed_setup_main
         Log in using the following credentials:
               Kali VMs:
                     Username: kali
                     Password: kali (only if you are using the official prebuilt Kali VM image, or if you set
                     these during installation)
               MS-2 Target VM:
                     Username: msfadmin
                     Password: msfadmin
  Step 2: Verify Network Configuration
      1. Identify IP Addresses:
               Open a terminal on each VM and use one of the following commands to retrieve its assigned IP
               address and network details:
                  ip addr show
               or
                  ifconfig
               Locate the inet (IPv4) address under the appropriate network interface:
                     For VirtualBox: Look for eth0 or enp0s3 (Host-Only Adapter).
                     For UTM (macOS): Look for eth0 or ens3 (NIC naming varies) on the Host Network
                     interface (recommended) or your chosen lab network interface.
         Expected IP Addresses (Example for consistency):
               Kali Attack VM: 192.168.10.11
               Kali Defense VM: 192.168.10.12
               MS-2 Target VM: 192.168.10.13
               If IP addresses are missing or incorrect, recheck your network settings in VirtualBox or UTM.
  Step 3: Test VM-to-VM Connectivity
  3.1: From Kali Attack VM
         Open a terminal and verify it can communicate with the other VMs:
2/12/26, 11:41 PM                                              testbed_setup_main
           ping 192.168.10.12            # Ping Kali Defense VM
           ping 192.168.10.13            # Ping MS-2 Target VM
  3.2: From Kali Defense VM
         Verify connectivity with the other machines:
           ping 192.168.10.11            # Ping Kali Attack VM
           ping 192.168.10.13            # Ping MS-2 Target VM
  3.3: From MS-2 Target VM
         Ensure it can reach both Kali VMs:
           ping 192.168.10.11            # Ping Kali Attack VM
           ping 192.168.10.12            # Ping Kali Defense VM
  Expected Results:
         Success: Replies from each machine indicate successful communication.
         Failure:
               If pings fail, check the VM's assigned IPs and ensure that each is using the correct Host-Only
               Adapter / Host Network (recommended) for the lab subnet.
               If you are using Bridged in UTM, ensure all VMs are bridged to the same physical interface
               and that your LAN allows host-to-host communication.
               Ensure that firewalls are disabled or allow ICMP traffic:
                  sudo ufw disable         # Disable UFW firewall in Kali Linux (if enabled)
  Step 4: Verify External Internet Access (Optional)
  If you enabled NAT (VirtualBox) or Shared Network (NAT / SLIRP in UTM) for internet access, test
  connectivity:
      1. Check DNS resolution:
           nslookup google.com
         or
2/12/26, 11:41 PM                                             testbed_setup_main
            dig google.com
      2. Ping an external server:
            ping -c 4 google.com
         If ICMP is blocked, try:
            curl -I https://www.google.com
  If internet access fails, ensure:
         NAT is enabled in VirtualBox (Adapter 2 for Kali VMs).
         Shared Network (NAT / SLIRP) is enabled in UTM (NIC 2, optional).
         The VM has a valid default gateway ( ip route show ).
  Troubleshooting Tips
         No response to pings:
               Verify that all VMs have the correct static IPs and are in the same subnet.
               Restart networking on the affected VM:
                  sudo systemctl restart networking
               If using UTM (macOS), ensure all VMs are attached to the same Host Network
               (recommended). If you used Bridged, ensure your LAN permits peer-to-peer connectivity.
               If using VirtualBox, ensure the Host-Only Network is correctly configured.
         Internet not working:
               Ensure NAT (VirtualBox) or Shared Network (UTM) is enabled.
               Manually add a DNS server (if necessary):
                  echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
         No Response to Pings:
               Ensure all VMs are powered on and properly configured to use the Host-Only Adapter / Host
               Network lab subnet.
2/12/26, 11:41 PM                                             testbed_setup_main
               Recheck the Host-Only Adapter settings in VirtualBox (or Host Network selection in UTM).
               Verify the IP addresses assigned to each VM using ifconfig or ip addr .
               Check firewall settings within each VM to ensure ICMP packets (ping) are not blocked.
         Incorrect IP Addresses:
               If IP addresses do not match the 192.168.x.x range:
                     For VirtualBox: verify the DHCP server settings in the Host Network Manager (if using
                     DHCP), or confirm your static-IP configuration.
                     For UTM Host Network: DHCP is typically not provided, so ensure you assigned static IPs
                     on the correct interface.
                     Restart the affected VM (or network interface) and recheck.
         Network Conflicts:
               If there are duplicate MAC addresses or IP conflicts:
                     Recheck that the option to Generate new MAC address of all network cards was
                     enabled during cloning (VirtualBox).
                     Assign static IP addresses to each VM if necessary.
         VMs Running Slowly?
               Increase allocated CPU/RAM.
               Use SSD storage for better performance.
         Metasploitable Won’t Boot?
               Ensure you selected the correct disk format (QCOW2 for UTM recommended, VMDK for
               VirtualBox).
               If using UTM on Apple Silicon, confirm you created the MS-2 VM under Emulate (not
               Virtualize).
  Quick Tutorial on VirtualBox Network
  Modes
  VirtualBox offers several network modes to configure virtual machines (VMs) based on their
  communication and connectivity needs. Here’s a detailed guide to help you understand and choose the
  right network mode for your VMs.
  For more detailed information on VirtualBox network modes, refer to the official documentation:
  VirtualBox Networking Guide.
2/12/26, 11:41 PM                                              testbed_setup_main
  Network Modes in VirtualBox
  1. NAT (Network Address Translation)
         How It Works:
         The VM connects to the Internet through the host using VirtualBox NAT. By default, the VM is not
         reachable from the host’s physical LAN, and inbound connections to the VM require explicit
         configuration (e.g., port forwarding).
         Use Case:
                Ideal for VMs that need outbound Internet access but do not need to be directly reachable
                from other devices on the LAN.
         Configuration Steps:
             i. Open the VM’s Settings > Network.
            ii. Enable a network adapter (e.g., Adapter 1 or Adapter 2) and set Attached To to NAT.
           iii. Save the configuration and start the VM.
         Advantages:
                Simple to set up.
                Provides basic isolation from the local network.
                Requires no additional network configuration.
         Disadvantages:
                Inbound connections to the VM are not possible without port forwarding.
                The VM does not appear as a peer device on the LAN.
         Example Use Case: A VM downloading updates or software tools from the Internet.
  2. Bridged Adapter
         How It Works:
         The VM appears as a separate device on the host’s physical network. It gets its own IP address
         (typically via DHCP) and can communicate with other devices on the network.
         Use Case:
                Ideal when the VM needs full LAN presence and must be reachable by other devices.
         Configuration Steps:
             i. Open the VM’s Settings > Network.
            ii. Enable a network adapter and set Attached To to Bridged Adapter.
           iii. Select the host network interface (e.g., Ethernet or Wi-Fi).
           iv. Save the configuration and start the VM.
         Advantages:
2/12/26, 11:41 PM                                              testbed_setup_main
                Allows the VM to act like a physical machine on the network.
                Supports inbound and outbound communication without port forwarding.
         Disadvantages:
                Exposes the VM to the local network (reduced isolation).
                May be restricted by enterprise networks or Wi-Fi policies.
         Example Use Case: Testing a server application accessible to other devices on the network.
  3. Host-Only Adapter
         How It Works:
         The VM connects to a private network created by VirtualBox. Only the host and other VMs on the
         same Host-Only network can communicate. Internet access is not provided unless you add another
         adapter (e.g., NAT). Host-Only networks may use DHCP (optional) or static IPs.
         Use Case:
                Ideal for testbed setups, where VMs need to communicate with each other while remaining
                isolated from the LAN.
         Configuration Steps:
             i. Open VirtualBox’s File > Tools > Network Manager (or Host Network Manager, depending
                on version).
            ii. Create a new Host-Only Network (if not already present) and optionally enable DHCP.
           iii. Open the VM’s Settings > Network.
           iv. Enable a network adapter and set Attached To to Host-Only Adapter.
            v. Select the configured Host-Only network.
           vi. Save the settings and start the VM.
         Advantages:
                Isolated from the Internet and host’s physical network (LAN).
                Enables secure VM-to-VM communication.
         Disadvantages:
                No Internet access unless combined with another adapter mode (e.g., NAT).
                IP management depends on whether DHCP is enabled; otherwise you must use static IPs.
         Example Use Case: A controlled environment for testing offensive and defensive security tools.
2/12/26, 11:41 PM                                              testbed_setup_main
  4. Internal Network
         How It Works:
         The VM connects to a private network visible only to other VMs on the same Internal Network. It is
         isolated from the host and the Internet.
         Use Case:
               Ideal for VM-only lab segments where even the host should not participate.
         Advantages:
               Full isolation from both the Internet and the host network.
         Disadvantages:
               No host connectivity.
               No built-in DHCP unless you run a DHCP server inside the internal network (or configure static
               IPs).
  5. NAT Network
         How It Works:
         Similar to NAT, but multiple VMs can be placed on the same NAT Network to communicate with
         each other while still having outbound Internet access (subject to the NAT Network configuration).
         Use Case:
               Ideal for scenarios where VMs need both Internet access and inter-VM communication, without
               exposing them to the host’s physical network.
         Advantages:
               Combines NAT-style isolation with VM-to-VM connectivity.
               Can be configured with DHCP in the NAT Network settings.
         Disadvantages:
               Slightly more configuration than basic NAT.
               Inbound access typically still requires port forwarding (configured on the NAT Network).
  Choosing the Right Network Mode
                                     Requirement                                      Recommended Mode
     Outbound Internet access                                                     NAT
     Full network access to other devices                                         Bridged Adapter
2/12/26, 11:41 PM                                             testbed_setup_main
                                     Requirement                                      Recommended Mode
     Secure communication between VMs                                            Host-Only Adapter
     Isolated VM network (no host communication)                                 Internal Network
     Internet and inter-VM communication                                         NAT Network
  Helpful Resources for Testbed Setup
  Official Documentation
      1. VirtualBox:
               VirtualBox Official Website: Download the latest version for your OS.
               VirtualBox User Manual (PDF): Comprehensive guide covering installation, configuration, and
               advanced settings.
               VirtualBox Networking Modes: Detailed explanation of networking options, including Host-Only
               and NAT.
      2. Kali Linux:
               Kali Linux Official Website: Access downloads, tools, and updates.
               Kali Linux Documentation: Step-by-step instructions for installing and configuring Kali Linux.
               Kali Tools Documentation: Information about the tools pre-installed in Kali Linux.
      3. Metasploitable-2:
               Metasploitable-2 Download: Download the Metasploitable-2 VM.
               Metasploit Framework Documentation: Guidance on using Metasploit to explore vulnerabilities.
  Community and Troubleshooting Resources
      1. VirtualBox Forums:
               VirtualBox Community Forum: Active user forum for resolving setup and configuration issues.
      2. Kali Linux Community:
               Kali Linux Forums: Get help from the official Kali Linux user community.
               Reddit: r/KaliLinux: Discussions and troubleshooting tips from the Kali Linux community.

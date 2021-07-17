[

  # bmp280@76 compatible="bosch,bmp280"
  "bmp280_spi"

  # bq24192@6b compatible="ti,bq24192"
  "bq24190_charger"

  # bt compatible="qcom,wcnss-bt"
  "btqcomsmd"

  # clock-controller compatible="qcom,rpmcc-msm8974"
  "clk_smd_rpm"

  # vibrator compatible="clk-vibrator"
  "clk_vibrator"

  # misc@900 compatible="qcom,pm8941-misc"
  "extcon_qcom_spmi_misc"

  # bluetooth compatible="brcm,bcm43438-bt"
  "hci_uart"

  # i2c@f9923000 compatible="qcom,i2c-qup-v2.1.1"
  # i2c@f9924000 compatible="qcom,i2c-qup-v2.1.1"
  # i2c@f9925000 compatible="qcom,i2c-qup-v2.1.1"
  # i2c@f9928000 compatible="qcom,i2c-qup-v2.1.1"
  # i2c@f9964000 compatible="qcom,i2c-qup-v2.1.1"
  # i2c@f9967000 compatible="qcom,i2c-qup-v2.1.1"
  # i2c@f9968000 compatible="qcom,i2c-qup-v2.1.1"
  "i2c_qup"

  # mpu6515@68 compatible="invensense,mpu6515"
  "inv_mpu6050_i2c"

  # led-controller@38 compatible="ti,lm3630a"
  "lm3630a_bl"

  # mdss@fd900000 compatible="qcom,mdss"
  # mdp@fd900000 compatible="qcom,mdp5"
  "msm"

  # qfprom@fc4bc000 compatible="qcom,qfprom"
  "nvmem_qfprom"

  # ocmem@fdd00000 compatible="qcom,msm8974-ocmem"
  "ocmem"

  # phy@a compatible="qcom,usb-hs-phy"
  # phy@b compatible="qcom,usb-hs-phy"
  "phy_qcom_usb_hs"

  # pwrkey@800 compatible="qcom,pm8941-pwrkey"
  "pm8941_pwrkey"

  # coincell@2800 compatible="qcom,pm8941-coincell"
  "qcom_coincell"

  # tcsr-mutex compatible="qcom,tcsr-mutex"
  "qcom_hwspinlock"

  # remoteproc@fc880000 compatible="qcom,msm8974-mss-pil"
  "qcom_q6v5_mss"

  # adsp-pil compatible="qcom,msm8974-adsp-pil"
  "qcom_q6v5_pas"

  # rng@f9bff000 compatible="qcom,prng"
  "qcom_rng"

  # charger@1000 compatible="qcom,pm8941-charger"
  "qcom_smbb"

  # smd compatible="qcom,smd"
  "qcom_smd"

  # pm8841-regulators compatible="qcom,rpm-pm8841-regulators"
  # pm8941-regulators compatible="qcom,rpm-pm8941-regulators"
  # pma8084-regulators compatible="qcom,rpm-pma8084-regulators"
  "qcom_smd_regulator"

  # iadc@3600 compatible="qcom,spmi-iadc"
  "qcom_spmi_iadc"

  # regulators compatible="qcom,pm8941-regulators"
  "qcom_spmi_regulator"

  # temp-alarm@2400 compatible="qcom,spmi-temp-alarm"
  # temp-alarm@2400 compatible="qcom,spmi-temp-alarm"
  "qcom_spmi_temp_alarm"

  # vadc@3100 compatible="qcom,spmi-vadc"
  "qcom_spmi_vadc"

  # thermal-sensor@fc4a9000 compatible="qcom,msm8974-tsens"
  "qcom_tsens"

  # remoteproc@fb21b000 compatible="qcom,pronto-v2-pil"
  # iris compatible="qcom,wcn3680"
  "qcom_wcnss_pil"

  # wled@d800 compatible="qcom,pm8941-wled"
  "qcom_wled"

  # interconnect@fc380000 compatible="qcom,msm8974-bimc"
  # interconnect@fc460000 compatible="qcom,msm8974-snoc"
  # interconnect@fc468000 compatible="qcom,msm8974-pnoc"
  # interconnect@fc470000 compatible="qcom,msm8974-ocmemnoc"
  # interconnect@fc478000 compatible="qcom,msm8974-mmssnoc"
  # interconnect@fc480000 compatible="qcom,msm8974-cnoc"
  "qnoc_msm8974"

  # synaptics@70 compatible="syna,rmi4-i2c"
  "rmi_i2c"

  # rmtfs@fd80000 compatible="qcom,rmtfs-mem"
  "rmtfs_mem"

  # rtc@6000 compatible="qcom,pm8941-rtc"
  "rtc_pm8xxx"

  # rpm_requests compatible="qcom,rpm-msm8974"
  "smd_rpm"

  # smem compatible="qcom,smem"
  "smem"

  # smp2p-adsp compatible="qcom,smp2p"
  # smp2p-modem compatible="qcom,smp2p"
  # smp2p-wcnss compatible="qcom,smp2p"
  "smp2p"

  # smsm compatible="qcom,smsm"
  "smsm"

  # reboot-mode compatible="syscon-reboot-mode"
  "syscon_reboot_mode"

  # avago_apds993@39 compatible="avago,apds9930"
  "tsl2772"

  # wifi compatible="qcom,wcnss-wlan"
  "wcn36xx"

  # wcnss compatible="qcom,wcnss"
  "wcnss_ctrl"

  # unmatched #device(name='', compatible=['lge,hammerhead', 'qcom,msm8974'])
  # unmatched #device(name='cpu@0', compatible=['qcom,krait'])
  # unmatched #device(name='cpu@1', compatible=['qcom,krait'])
  # unmatched #device(name='cpu@2', compatible=['qcom,krait'])
  # unmatched #device(name='cpu@3', compatible=['qcom,krait'])
  # unmatched #device(name='l2-cache', compatible=['cache'])
  # unmatched #device(name='spc', compatible=['qcom,idle-state-spc', 'arm,idle-state'])
  # unmatched #device(name='cpu-pmu', compatible=['qcom,krait-pmu'])
  # unmatched #device(name='xo_board', compatible=['fixed-clock'])
  # unmatched #device(name='sleep_clk', compatible=['fixed-clock'])
  # unmatched #device(name='timer', compatible=['arm,armv7-timer'])
  # unmatched #device(name='scm', compatible=['qcom,scm'])
  # unmatched #device(name='soc', compatible=['simple-bus'])
  # unmatched #device(name='interrupt-controller@f9000000', compatible=['qcom,msm-qgic2'])
  # unmatched #device(name='syscon@f9011000', compatible=['syscon'])
  # unmatched #device(name='timer@f9020000', compatible=['arm,armv7-timer-mem'])
  # unmatched #device(name='power-controller@f9089000', compatible=['qcom,msm8974-saw2-v2.1-cpu', 'qcom,saw2'])
  # unmatched #device(name='power-controller@f9099000', compatible=['qcom,msm8974-saw2-v2.1-cpu', 'qcom,saw2'])
  # unmatched #device(name='power-controller@f90a9000', compatible=['qcom,msm8974-saw2-v2.1-cpu', 'qcom,saw2'])
  # unmatched #device(name='power-controller@f90b9000', compatible=['qcom,msm8974-saw2-v2.1-cpu', 'qcom,saw2'])
  # unmatched #device(name='power-controller@f9012000', compatible=['qcom,saw2'])
  # unmatched #device(name='clock-controller@f9088000', compatible=['qcom,kpss-acc-v2'])
  # unmatched #device(name='clock-controller@f9098000', compatible=['qcom,kpss-acc-v2'])
  # unmatched #device(name='clock-controller@f90a8000', compatible=['qcom,kpss-acc-v2'])
  # unmatched #device(name='clock-controller@f90b8000', compatible=['qcom,kpss-acc-v2'])
  # unmatched #device(name='restart@fc4ab000', compatible=['qcom,pshold'])
  # unmatched #device(name='clock-controller@fc400000', compatible=['qcom,gcc-msm8974'])
  # unmatched #device(name='syscon@fd4a0000', compatible=['syscon'])
  # unmatched #device(name='syscon@fd484000', compatible=['syscon'])
  # unmatched #device(name='clock-controller@fd8c0000', compatible=['qcom,mmcc-msm8974'])
  # unmatched #device(name='memory@fc428000', compatible=['qcom,rpm-msg-ram'])
  # unmatched #device(name='serial@f991d000', compatible=['qcom,msm-uartdm-v1.4', 'qcom,msm-uartdm'])
  # unmatched #device(name='serial@f991e000', compatible=['qcom,msm-uartdm-v1.4', 'qcom,msm-uartdm'])
  # unmatched #device(name='serial@f995d000', compatible=['qcom,msm-uartdm-v1.4', 'qcom,msm-uartdm'])
  # unmatched #device(name='serial@f9960000', compatible=['qcom,msm-uartdm-v1.4', 'qcom,msm-uartdm'])
  # unmatched #device(name='sdhci@f9824900', compatible=['qcom,msm8974-sdhci', 'qcom,sdhci-msm-v4'])
  # unmatched #device(name='sdhci@f9864900', compatible=['qcom,msm8974-sdhci', 'qcom,sdhci-msm-v4'])
  # unmatched #device(name='sdhci@f98a4900', compatible=['qcom,msm8974-sdhci', 'qcom,sdhci-msm-v4'])
  # unmatched #device(name='bcrmf@1', compatible=['brcm,bcm4339-fmac', 'brcm,bcm4329-fmac'])
  # unmatched #device(name='usb@f9a55000', compatible=['qcom,ci-hdrc'])
  # unmatched #device(name='pinctrl@fd510000', compatible=['qcom,msm8974-pinctrl'])
  # unmatched #device(name='ak8963@f', compatible=['asahi-kasei,ak8963'])
  # unmatched #device(name='spmi@fc4cf000', compatible=['qcom,spmi-pmic-arb'])
  # unmatched #device(name='pm8841@4', compatible=['qcom,pm8841', 'qcom,spmi-pmic'])
  # unmatched #device(name='mpps@a000', compatible=['qcom,pm8841-mpp', 'qcom,spmi-mpp'])
  # unmatched #device(name='pm8841@5', compatible=['qcom,pm8841', 'qcom,spmi-pmic'])
  # unmatched #device(name='pm8941@0', compatible=['qcom,pm8941', 'qcom,spmi-pmic'])
  # unmatched #device(name='gpios@c000', compatible=['qcom,pm8941-gpio', 'qcom,spmi-gpio'])
  # unmatched #device(name='mpps@a000', compatible=['qcom,pm8941-mpp', 'qcom,spmi-mpp'])
  # unmatched #device(name='pm8941@1', compatible=['qcom,pm8941', 'qcom,spmi-pmic'])
  # unmatched #device(name='dma-controller@f9944000', compatible=['qcom,bam-v1.4.0'])
  # unmatched #device(name='etr@fc322000', compatible=['arm,coresight-tmc', 'arm,primecell'])
  # unmatched #device(name='tpiu@fc318000', compatible=['arm,coresight-tpiu', 'arm,primecell'])
  # unmatched #device(name='replicator@fc31c000', compatible=['arm,coresight-dynamic-replicator', 'arm,primecell'])
  # unmatched #device(name='etf@fc307000', compatible=['arm,coresight-tmc', 'arm,primecell'])
  # unmatched #device(name='funnel@fc31b000', compatible=['arm,coresight-dynamic-funnel', 'arm,primecell'])
  # unmatched #device(name='funnel@fc31a000', compatible=['arm,coresight-dynamic-funnel', 'arm,primecell'])
  # unmatched #device(name='funnel@fc345000', compatible=['arm,coresight-dynamic-funnel', 'arm,primecell'])
  # unmatched #device(name='etm@fc33c000', compatible=['arm,coresight-etm4x', 'arm,primecell'])
  # unmatched #device(name='etm@fc33d000', compatible=['arm,coresight-etm4x', 'arm,primecell'])
  # unmatched #device(name='etm@fc33e000', compatible=['arm,coresight-etm4x', 'arm,primecell'])
  # unmatched #device(name='etm@fc33f000', compatible=['arm,coresight-etm4x', 'arm,primecell'])
  # unmatched #device(name='opp_table', compatible=['operating-points-v2'])
  # unmatched #device(name='adreno@fdb00000', compatible=['qcom,adreno-330.2', 'qcom,adreno'])
  # unmatched #device(name='dsi@fd922800', compatible=['qcom,mdss-dsi-ctrl'])
  # unmatched #device(name='panel@0', compatible=['lg,acx467akm-7'])
  # unmatched #device(name='dsi-phy@fd922a00', compatible=['qcom,dsi-phy-28nm-hpm'])
  # unmatched #device(name='imem@fe805000', compatible=['syscon', 'simple-mfd'])
  # unmatched #device(name='gpio-keys', compatible=['gpio-keys'])
  # unmatched #device(name='vreg-boost', compatible=['regulator-fixed'])
  # unmatched #device(name='vreg-vph-pwr', compatible=['regulator-fixed'])
  # unmatched #device(name='wlan-regulator', compatible=['regulator-fixed'])
]

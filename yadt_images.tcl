################################################################################
#
#  yadt_images - module for YaDT
#           provides images
#
#
#
#------------------------------------------------------------------------------
#
#  Packages  required:
#  Packages  dependencies:
#
################################################################################

package provide YadtImg 1.0

#===============================================================================

namespace eval ::YadtImg {

}

#===============================================================================

proc ::YadtImg::Load_Images {} {

    image create photo firstDiffImage\
        -format gif\
        -data {
R0lGODlhFAAUAOf8AAABAAACAAAUAAIsAAItAQAvAAQ1AAA3AAA6AQI8AAA/AABBAABDAgBKAQNO
AABRAABUAQBeAABlAABmAABnAABoAABpAQBqAgBvAABxAABzAAB0AQN1AgB4AAB6AAB7AAB8AAB9
AAJ+AAeAAgCCAwCEAACFAACHAAKIAAaJAACMAQCNAwCOAACQAACRAAOSAACVAAmUAACXAQCaAAGc
AC2TESiaGjijGj+hJEOjG0WlHT6oIEinIECqIkOsJUeuHEWuJ06tJ0qwH0ewKUmxK1GvKkyyIkS1
I1OxLEa3JT26J0+1JE21LlyxLUe4JlC2Jki5KFuyNmKwNk+3MF6zL1yzN1+0MF20OGG1MVO6NE29
LGC2OkjAJGS4NWK4PF27Nle+OF+8N2a6N1HBMEzEKGe7OFPCMVnAOWi8OWa8QFXENFvCO1DHLGe+
Qmq+Om+8Qmi/Q1fGNlLJLmzAPGrARFDJOHG/RGvBRVTKMGLGN2nEN3PARVXLMWrFOFvRN3DLPl3T
OWvPQHXLTl/UO2jTO23RQ2nUPG3VNHfRRHXRTGrWPWzXPnPVPnHVRm3YP3fUTnDZN27ZQXrVR3TX
SXHaOW/aQnzWSXDbQ3bZS3PcO3jaQ3LcRHvYUnXdPHPdRXjbTH/ZTHbePXTfRnndToHbTnfgP3Xg
R4DcVnjhQHbhSIXbXnniQXfiSoTeUHvjQnnjS3zkQ3rkTHvlTX7mRXzmTorgYo/faY3hXH/oR33o
T4DpSH7pUI/jXoLqSYDqUY7kZoPrSoHrUpPjbYTsS5jidILsU4XtTIPtVZHnaYbuTYTuVofvT5zl
d6DkfoXwV6Hlf5TrbIfxWIryUYjyWaPngInzWpftbqjmiKTogYz0U4r0W4/yYov1XJ3td6bqhIz2
XaTripT1XajshY34XqbsjKDweanthqHxeqjvjq/tjqPzfJj5YZH7Yp/1dpL8Y63xipP9ZLHwkbDx
mKv1hrPykrD0jbTzk7nymrb1lbL3j7D3lbv0nP///////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjvAP/9+0CwoMGDBAUKxMOtWjVlx4LRovXKVRkfBRRq/PfE
W6dNmwwZwpIjwMaT/wZ9y0YnSwCUG+O8myXr1StPW4oEOLmvp8+fQHuiHPSt2jRlwYChYZLgpAoT
UPHY6+WLVqxXW4iEIBgCpRlzoTx5AomFRwCYAm0cgfLEiBAhO2qg3Beqrt27eEN9QDvmDRgHaDcO
4lZN2TI6TBYEHvSNWzVlx4LRQoQGSICTXLhVm7dvWTBftGKJDRVmRwCUdeL1oiXLZpciAQKrMefK
pqdNWHgECAzFW6dNwA1hyREg8JNnzGphOkQIS44AgaNrDAgAOw==
}

#===============================================================================

    image create photo prevDiffImage\
        -format gif\
        -data {
R0lGODlhFAAUAOf8AAABAAACAAAUAAIsAAItAQAvAAQ1AAA3AAA6AQI8AAA/AABBAABDAgBKAQNO
AABRAABUAQBeAABlAABmAABnAABoAABpAQBqAgBvAABxAABzAAB0AQN1AgB4AAB6AAB7AAB8AAB9
AAJ+AAeAAgCCAwCEAACFAACHAAKIAAaJAACMAQCNAwCOAACQAACRAAOSAACVAAmUAACXAQCaAAGc
AC2TESiaGjijGj+hJEOjG0WlHT6oIEinIECqIkOsJUeuHEWuJ06tJ0qwH0ewKUmxK1GvKkyyIkS1
I1OxLEa3JT26J0+1JE21LlyxLUe4JlC2Jki5KFuyNmKwNk+3MF6zL1yzN1+0MF20OGG1MVO6NE29
LGC2OkjAJGS4NWK4PF27Nle+OF+8N2a6N1HBMEzEKGe7OFPCMVnAOWi8OWa8QFXENFvCO1DHLGe+
Qmq+Om+8Qmi/Q1fGNlLJLmzAPGrARFDJOHG/RGvBRVTKMGLGN2nEN3PARVXLMWrFOFvRN3DLPl3T
OWvPQHXLTl/UO2jTO23RQ2nUPG3VNHfRRHXRTGrWPWzXPnPVPnHVRm3YP3fUTnDZN27ZQXrVR3TX
SXHaOW/aQnzWSXDbQ3bZS3PcO3jaQ3LcRHvYUnXdPHPdRXjbTH/ZTHbePXTfRnndToHbTnfgP3Xg
R4DcVnjhQHbhSIXbXnniQXfiSoTeUHvjQnnjS3zkQ3rkTHvlTX7mRXzmTorgYo/faY3hXH/oR33o
T4DpSH7pUI/jXoLqSYDqUY7kZoPrSoHrUpPjbYTsS5jidILsU4XtTIPtVZHnaYbuTYTuVofvT5zl
d6DkfoXwV6Hlf5TrbIfxWIryUYjyWaPngInzWpftbqjmiKTogYz0U4r0W4/yYov1XJ3td6bqhIz2
XaTripT1XajshY34XqbsjKDweanthqHxeqjvjq/tjqPzfJj5YZH7Yp/1dpL8Y63xipP9ZLHwkbDx
mKv1hrPykrD0jbTzk7nymrb1lbL3j7D3lbv0nP///////////////yH5BAEKAP8ALAAAAAAUABQA
QAjdAP8JHEiwoEGBeLhVq6bsWDBatF65KuOjwMF/T7x12rTJkCEsOQJcJDjoWzY6WQKMHBjn3SxZ
r1552lIkwEqCNALcHDjoW7VpyoIBQ8MkgUEVJpLisdfLF61Yr7YQCfHhQ4iDZsyF8uSJIxYeAVba
OALliREhQnbU2Ml25Jg3YBy0HcStmrJldJgsWDnoG7dqyo4Fo4UIDZAABrlwqzZv37JgvmjF4hoq
zI4AB+vE60VLVswuRQKsVGPOVUxPm7DwCLASirdOHDcZwpIjwMonz5jVwnSIEJYcAdreDAgAOw==
}

#===============================================================================

    image create photo nextDiffImage\
        -format gif\
        -data {
R0lGODlhFAAUAOf8AAABAAACAAAUAAIsAAItAQAvAAQ1AAA3AAA6AQI8AAA/AABBAABDAgBKAQNO
AABRAABUAQBeAABlAABmAABnAABoAABpAQBqAgBvAABxAABzAAB0AQN1AgB4AAB6AAB7AAB8AAB9
AAJ+AAeAAgCCAwCEAACFAACHAAKIAAaJAACMAQCNAwCOAACQAACRAAOSAACVAAmUAACXAQCaAAGc
AC2TESiaGjijGj+hJEOjG0WlHT6oIEinIECqIkOsJUeuHEWuJ06tJ0qwH0ewKUmxK1GvKkyyIkS1
I1OxLEa3JT26J0+1JE21LlyxLUe4JlC2Jki5KFuyNmKwNk+3MF6zL1yzN1+0MF20OGG1MVO6NE29
LGC2OkjAJGS4NWK4PF27Nle+OF+8N2a6N1HBMEzEKGe7OFPCMVnAOWi8OWa8QFXENFvCO1DHLGe+
Qmq+Om+8Qmi/Q1fGNlLJLmzAPGrARFDJOHG/RGvBRVTKMGLGN2nEN3PARVXLMWrFOFvRN3DLPl3T
OWvPQHXLTl/UO2jTO23RQ2nUPG3VNHfRRHXRTGrWPWzXPnPVPnHVRm3YP3fUTnDZN27ZQXrVR3TX
SXHaOW/aQnzWSXDbQ3bZS3PcO3jaQ3LcRHvYUnXdPHPdRXjbTH/ZTHbePXTfRnndToHbTnfgP3Xg
R4DcVnjhQHbhSIXbXnniQXfiSoTeUHvjQnnjS3zkQ3rkTHvlTX7mRXzmTorgYo/faY3hXH/oR33o
T4DpSH7pUI/jXoLqSYDqUY7kZoPrSoHrUpPjbYTsS5jidILsU4XtTIPtVZHnaYbuTYTuVofvT5zl
d6DkfoXwV6Hlf5TrbIfxWIryUYjyWaPngInzWpftbqjmiKTogYz0U4r0W4/yYov1XJ3td6bqhIz2
XaTripT1XajshY34XqbsjKDweanthqHxeqjvjq/tjqPzfJj5YZH7Yp/1dpL8Y63xipP9ZLHwkbDx
mKv1hrPykrD0jbTzk7nymrb1lbL3j7D3lbv0nP///////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjcAP8JHEiwoEGCdeL1oiXr1asuRQIcNDjmDRgHEwtC8dZp
k0dDWHIEyDjoG7dqyo4Fo4UIDZAAGZ88Y1YL0yFCWHIEyPhPjTlXDj1twsIjwEEu3KrN27csmC9a
sTx5ChVmR4CJg7hVU7aMDpMFPMPytHEEyhMjQoTsqBH2ibdOHg0ZwpIjAE8z5kJJ9YiFRwCecd7N
kuXQ05YiAQyqMMEYj71evmjFerWFSIgPH0IUxMOtWjVlx4LRovXKVRkfBSYO+lZtmrJgwNAwSSB2
0LdsdLIEEEuQRgDewAUGBAA7
}

#===============================================================================

    image create photo lastDiffImage\
        -format gif\
        -data {
R0lGODlhFAAUAOf8AAABAAACAAAUAAIsAAItAQAvAAQ1AAA3AAA6AQI8AAA/AABBAABDAgBKAQNO
AABRAABUAQBeAABlAABmAABnAABoAABpAQBqAgBvAABxAABzAAB0AQN1AgB4AAB6AAB7AAB8AAB9
AAJ+AAeAAgCCAwCEAACFAACHAAKIAAaJAACMAQCNAwCOAACQAACRAAOSAACVAAmUAACXAQCaAAGc
AC2TESiaGjijGj+hJEOjG0WlHT6oIEinIECqIkOsJUeuHEWuJ06tJ0qwH0ewKUmxK1GvKkyyIkS1
I1OxLEa3JT26J0+1JE21LlyxLUe4JlC2Jki5KFuyNmKwNk+3MF6zL1yzN1+0MF20OGG1MVO6NE29
LGC2OkjAJGS4NWK4PF27Nle+OF+8N2a6N1HBMEzEKGe7OFPCMVnAOWi8OWa8QFXENFvCO1DHLGe+
Qmq+Om+8Qmi/Q1fGNlLJLmzAPGrARFDJOHG/RGvBRVTKMGLGN2nEN3PARVXLMWrFOFvRN3DLPl3T
OWvPQHXLTl/UO2jTO23RQ2nUPG3VNHfRRHXRTGrWPWzXPnPVPnHVRm3YP3fUTnDZN27ZQXrVR3TX
SXHaOW/aQnzWSXDbQ3bZS3PcO3jaQ3LcRHvYUnXdPHPdRXjbTH/ZTHbePXTfRnndToHbTnfgP3Xg
R4DcVnjhQHbhSIXbXnniQXfiSoTeUHvjQnnjS3zkQ3rkTHvlTX7mRXzmTorgYo/faY3hXH/oR33o
T4DpSH7pUI/jXoLqSYDqUY7kZoPrSoHrUpPjbYTsS5jidILsU4XtTIPtVZHnaYbuTYTuVofvT5zl
d6DkfoXwV6Hlf5TrbIfxWIryUYjyWaPngInzWpftbqjmiKTogYz0U4r0W4/yYov1XJ3td6bqhIz2
XaTripT1XajshY34XqbsjKDweanthqHxeqjvjq/tjqPzfJj5YZH7Yp/1dpL8Y63xipP9ZLHwkbDx
mKv1hrPykrD0jbTzk7nymrb1lbL3j7D3lbv0nP///////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjuAP8JHEiwoEGCdeL1oiXr1asuRQIcNDjmDRgHEwtC8dZp
k0dDWHIEyDjoG7dqyo4Fo4UIDZAAGZ88Y1YL0yFCWHIEyPhPjTlXDj1twsIjwEEu3KrN27csmC9a
sTx5ChVmR4CJg7hVU7aMDpMFB/eFGku2rNlQHwzaOALliREhQnbU4PnvibdOHg0ZwpIjAE8z5kJJ
9YiFRwCecd7NkuXQ05YiAQyqMEEZj71evmjFerWFSIgPH0IUxMOtWjVlx4LRovXKVRkfBSYO+lZt
mrJgwNAwSUD336Bv2ehkCTBxn/HjyJMbJwi6ufPnzf8FBAA7
}

#===============================================================================

    image create photo centerDiffImage\
        -format gif\
        -data {
R0lGODlhFAAUAKEDAAAAABQUdv8AAP///yH5BAEKAAMALAAAAAAUABQAQAJgnI+poH1ggHPAgBGy
3nsAAwzcqA2AAUwNYACqAhjAINT2fQ+AAUwNYAAIh8Ti0GBMFg0AnwJgADgTAANgkMlqtwOAATDA
iW0DgAEwRQAMgPQBYAAMtvTsAGAAuA2AvaIAADs=
}

#===============================================================================

    image create photo previewImage\
        -format gif\
        -data {
R0lGODlhFAAUAMIBAAAAABQUdv/2AP///xQUdhQUdhQUdhQUdiH+EUNyZWF0ZWQgd2l0aCBHSU1Q
ACH5BAEKAAQALAAAAAAUABQAQAOMSLrcHiuIMYQVgQUVCPhgqARKoAROugRKwASXFTSBEqhqoAQE
oAQxQUDxIQQUgUUgaAkwAooAThEgBBQBRWDL7Xq5iq/YqwgQQmg0IaAINLyOgCKwCFgolwAjoAgQ
AAQBAgNBAQQfBAEKAQsBTAIBDAEKAQQfCl4EWwsBCgFTCgEEAQQBCgGgDQGpOAkAOw==
}

#===============================================================================

    image create photo findImage\
        -format gif\
        -data {
R0lGODlhFAAUAOeLAAAAAAECBBEREBkZGSgmJSkpKS4pJSwsLC4uLjQwLDQ0NDY0MTU1NTk5Nzs6
Nzw8PEE/PEBAQEJCQkZFQkVFRUdGREhISEpKSktLS1BNSU9PT1BQUFJQTVFRUVNTUlNTVFhWVFdX
V1tbW1xcXF1dXWBgYGFhYWJiYmRkZGZmZmhnaGxoY2ppZmdteG5ubnNzc251f3Z2dnZ2eHl5eW58
kXuAhneClYKCgoeHh4SKqYuLi4+MiHaRupCQkIOSpICTppOTk5STlJWVlZaWlo+XopiYmJSYrJCZ
sZmZmZubm5ubnIGf0X2i156enp+fn6CgoKKiooOo3KWlpZOtzaqqqqqqrYWw4Iaw5aysrK2sq62t
ra+vr5G02bGxsbu7u6W+5L+/v8DAwJfI98HBwcLCwpbK/qXH8cPDw8TExLvF35nM/sXFxZvN/sbG
xsnIxp/P/snJycrKyp7U/6jU/8jO4K3Z/7Xa/7fa/8Ta+NnZ2b3f/8ve98Xh/97e3cfi/8nj/8rj
/uDg4M/m/urq5+nz/Ov1/+z1/vj49/j4+Pn5+fv7+4O/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CSH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAAAjXAP8JHEiwoMGDCBMqXMhQYQcNFBae2PACh5AnTpo4EfIA
oQgSccJ0oSIFipMmSJKgGFBQAgUdZ+CM0XLjRIcHF4rkIUOioAJFM9a40ILGAoYYHcAEQnQoiIqB
BUZ4KQEmUKJBMlh86NGmjxE6eGAMRLDBxJY1bnKk+VJBCZYqewwJqmNg4IEQQLIcIVTIz48IQ4jo
4XNHToKCKXaYAfTHDhcCDGqweSNmigCDK8rMmaPGh0AOPJgsAXGwAY0rVqJAGOjAwwIACCe0sJEB
QEOCAW7r3s0bYUAAOw==
}

#===============================================================================

    image create photo findNextImage\
        -format gif\
        -data {
R0lGODlhFAAUAOe2AAAAAA0NDBUVFR0bGgAxAiYmJignJTArJzIuKi4vLzMzMjMzMzo3NDo6OkA/
PUJAPEFBQUNDQ0ZGRkdHR0lIRkpIRkpKSk1MSU5MSQBuAE9PT1BQUFBQUVFRUQByAABzAFNTUwV0
A1VVVQZ1Aw50CFdXVwB6AFlZWQp5BlpaWgl7BV9fX2NjY2djXmFkagCNAGdlYmlmaWdnZyiGIBWO
D3FpcGxscBeSDnR0dGt2hjKVGHZ3fHl5eXV7hx2hE3t7exyiEnx8fHl9gnR+iyajGSWlF0OgLkKi
LYOGg3OIqm6UckanLo2Kh4CNnYyOjJSMlJCQkJKSkpKSl3mefHmefYyTs4yVoJOVk5WVloOZrpKY
r2SwZI+btnyf05ycnIWgy56enp+fn6Ojo6SkpIao2aekp4Ks3ZOqx6enq2rFOIOt5KqqqKqqqq2t
rXHLPpG02HTMQnbNRHrNSbKysnnORW3UOX7PTnPXQbe3t3bcQ3feRJTE9ZPG+r+/v3rgRsHBwXvj
SMPCwJfK/MPDw37kS8TExJnM/sXFxX7nS5zN/YHnTqfL9YDoTbDM88nJyZzR/4XsUqXT/4buUonv
Vs/Pz8bR563a/7TY/5XxZrTZ/9bW1qnthLnc/9Xa6Nvb2cHf/tzb2MXg/5r9YrDzicfh/t3e3d7e
3sbi/57+Zsvi/aD/Z87j+7b3j87l/rn5lfHw7vTv9Ofz/+jz/vn5+f77/v7+/oO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CSH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAAAj+AP8JHEiwoMGDBl8gXCiQSBGGBD1k+GCChiofEAUu2TSK
lStMqIBkPHJHDyBGkCaJugHRSJ08fggpkmQHBUIJIGroSOMGThxEckIQZLHhRxQvYsKUmUJFCQEV
dEYQPCGDUp85bMaIAXPFCZIYM0gQhCAhyB9Hh8TgSNGhgQU2sLY8EUBwQa0fhVj00VRiAg8ReErR
eiXFxsACG+acKGRqFqgdMDhEKeRJS6dUQwhqYNFmUKAqlRpRwMIGzSpZrSwdIAgCyhousmKFyhIB
ihVOny49QlBwBZNFpE5lejMggRBDifacCWCwBZ9IkQQ1EXghSZcvGBDmUGOGDIOBCioOGACA0IGL
Hg8AZFw/MCAAOw==
}

#===============================================================================

    image create photo findPreviousImage\
        -format gif\
        -data {
R0lGODlhFAAUAOe4AAAAAA0NDB0bGoEAACAgICYmJq0CALQAACgnJcEDADArJzIuKi4vL74MADMz
MjMzMzo3NDo6Os8XAOQRAEA/PdcZAEJAPEFBQfAWAENDQ0REREZGRkdHR8knCElIRkpIRkpKSpc3
Nk1MSU5MSfkkAE9PT1BQUFBQUdsvCVFRUdwxAVNTU1VVVVdXV1lZWVpaWl9fX2NjY2djXmFkamVl
ZWdlYuZIEOFMCWZoaGlpabJXUmxscGNxdGxwcOVXEv9VDP5WCv1WEWt2hv9WEHV1dehdFf9XEXZ2
dnZ3fOdgFnl5eehiF/9cGv5dFPhfF3V7h8pmXnt7e/5gEXx8fHl9gnR+i/5iF/9iFv5nGf9nGf9p
G/5rGv9rG3OIqv9uHP9wHI2Kh/90HoCNnY2Njf94I5CQkMyDepKSkpKSl8aFgceFf4yTs4yVoJWV
loOZrv+CN5iYmJKYr52YmI+btsePjHyf052dnYWgy6GdnaSgn4ao2YKs3f+UX5Oqx6enq4Ot5Kqq
qKqqqq2trauwsZG02P+gaqe0tbKysrC4uLe3t/+qZ/+ra/+scv+veZTE9ZPG+sHBwcPCwJfK/MPD
w8TEw8TExJnM/sTFxZzN/afL9bDM85zR/6XT/8nOzsrR0cbR563a/7TY/7TZ/9bW1rnc/9jY2NXa
6Nvb2cHf/tzb2MXg/8fh/t7e3sbi/8vi/c7j+87l/uzs7PDw7ufz/+jz/vf39/n5+f7+/oO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CSH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAAAj+AP8JHEiwoEGCFQ4qHCjBxkKFCRqpaDABA4mHAg8UkvKG
0SJFZDAa4APECpYtX8JowTiASZAmV7Jw8eIEo8AhRnwUSbLkBg+MPUL86EAnjRozg+xoUOgihycd
KBDlwSMHTpkxNAgUvLBhCqROUAwReZEiAohAsUodKfjgVpRLOCiNasFBCYtErGrJQrNjYAETh1xU
YmUrFZIaJ85UOhXHlKsqBEvEEDQp0ppPmjy0CeTnFS1YoBQQXFEG0Bxas1S5yVCGDSlUoTYtKAgD
TKZVrUQREsCAiiVMjvoEMCjjESdOksQIFNGlzp0RCoX82aMHwkAHHxAAUEhhxhMLAGwEih8YEAA7
}

#===============================================================================

    image create photo saveImage\
        -format gif\
        -data {
R0lGODlhFAAUAOe3AAdIAAtLAx9TFA5nDBplChBoDRJpDhNqEBhrBRVrERpsBiBsGxZ0EEliRCNz
EFthWCyJE2lvZQmeAA2fAHF3bnJ4bxOhABaiAhmjBBukBnl/dR+mCyGnDTahFyOoEBGtFH2DeUub
KSWqEVOYPjqkHE2dKyerEyyoKIGHfSmsFVObRyqtF1ScSDqnKCyuGDuoKTSrIjGvCFaeSjypKzas
IzOwCjqtGTetJDSxDVigTDiuJTayDzqvJ1SmOzezET6wHTuwKD+xHjm0Ez2xKXmYcF+kSUmvHjq1
FUGyID6yKnebbD+zK1+mUjy3Fz24GGemU2OoTT65GmKpVUu0LWeoW0C6HE21LkG7HV2vQ0i5KFuw
S16wREO8H1yxTES9IGiuUoOiekW+IZKdjEe/I2ayTlC9In6ocUjAJFG+I0nBJlK/JVTAJlXCJ4es
fFbDKVfEKoSxf1rGLGrARI+vhmXJO5G2hWbLPGjMPZG5jmnNPpe4jmrOP66wra60qqS8obK4rqe+
o7e+s7nAtb2/vLvCt77EucLEwcDGvL3ItsHHvcTGw8TLwL/NwcDOwsPOvMjPxM3Py8vRxsXTxs7Q
zMzSx8bUx8/Rzs3TydDSz9HT0NLU0dPV0tXX1NbY1dja1tnb19vd2tze293f3N7g3d/h3uDi3+Hk
4OTm4+Xn5Obo5efp5ujq5+nr6Ors6evu6u3v6+/x7vHz8PL08fP18vf59vj69/n7+P//////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP/9KyPHEaWDjxYVIhToTx8yRgQK9OBhBiJJkSpJetSo
UaJCgrZw4VJAIJIjR4gUGVnHFS1Wk0qsWUMnToJ/ZS5MaGGKlqpJQIFuIuVJyxEuA/6t2VGjRg8p
UpjkkMGCxQgSP36USWNA4IQJJ1TZWhV0EqRNpj51gdCBwT81Hi7MCPXKVNlJmj5t0jJygEAbFFfY
aLpjhxCUR0aOGVPg35ojhed8QWnGECdVrkKMSUNnzQGJ/xQ0oKABBQoQFSI8EECAwAIAEldMOJGK
Vq1ZsmCxSmWKlKcuSH44+Ffm6wlVtmzJigWLVSpTpDxpQXIEgcALE2aYigVLlapUpkaLiRrFScvI
Af/UUJzhSZWpUaNEffrkyVMmLCML/FtD0QON/zzwAMQQSSxhhRVZcDFGAQLVYIMNTdVQmBCIjcTF
GGcY8M8ahe2gByB4tCEGH4p4YkoIi9GxhgH/lIEYGFCgBIcnrdBiSglprEFHHAdI9AMXRCjxBBV+
2LIKJ4OEsEYce5QRAGhQRhllQAA7
}

#===============================================================================

    image create photo saveAsImage\
        -format gif\
        -data {
R0lGODlhFAAUAOf/AAABAAAUAAolAIMCAIsAAw4lCZAAAAItAZkCAIEKC3kRAQA3ArIJAgBAAHEc
GmEmCb8LACE5HQRGAMAOBQBIABNDBF0tCjs0L2AvBig6QwBNACw8LB5EDs0SAFQ1C0c6CTc7MC1D
CDZBCRZLDBtJEipHC9oWAxVNJy9IGkM/Ph5QCT9DPQRaB1c9ODhIN2I8O+kcAB1YCdciAgBjADJS
NI03OdAnE+EkAENNPm5BQkpMSkFTN11KR0NTQyNjDlNSUExWWUhaPh5vC4VMO8c7LipsF9Y4KLdC
InZSROk2E69GKdM9GUJlOnJVTU9gT/80ALlGIi1yEcJFIVteXqRNNkVlfj9qZVBpSyl6FshKH+xC
F6JVPP5BANhKHf9CEJBdTiuBFWhnZepJKHtlXWttauVQJIRnXv9LEmRyWyeMEf9NHlp5UwWdAHRy
dv9TH5V0HW53eHF1g/9VKBKgAOZcM/pXLTiTGTOYGWSDXP9cKhylCDSeE31+e91nRXmBhCOoDyyl
G0mYSmyLZP9lMjmkGoKDjOtqVDSoEimsFYiHbYGIimeVWYaIhWuUXiyuGJKGhjisF5SGgUOnMjOw
Cj6sJLCOADKxHTayD9p4bEiuHDi0Ej+xHouRlISVgo+Rjjy3F0C2I5aThVOvQj+5G0O1OsCKf1C2
JpWXlEK8Hka5MVG1Q0W+IZWbkZacklW6K26tbEjAJJeeoJ2fnFXBJ4esfJKoiE/GK8SYoWDCKpKr
g1nFK6Smo/iRfp2qnp+qmaGoqm+9c17KMGbIMJSxlHLEV6qsqGXPLH+/kKOwwcipoquws6izob6r
wJ28n7K0sa+6qIDOb/GpnKPAsZrDt4DYYq3Gnry/wr7AvbnEst65uqbKxnLqMq7J1MXHxL3I05zZ
j8TJy8nLyNLJws7Qzd3NyOjKybzU8NLU0bLip9bY1drc2Nfd393f3Onc3ODi3uPl4uLl6PDqwefp
5vbm4eXq7evu6+D36Or14vDy7/X39PD69Pj69/H8+Pn+//3//P///yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP/9EyYMm0GDz54tW+bLlytKjQQK+0NxnLp0F9fxWqfo
SQ5Io2Bp+JdplEk8Jkd5kuevnjpYs2ZR0zVS2Jyb9fbhC8ez5y5lbrx4oDBwktFJly6psiFHRrtA
JmFJrcmGzRx8+/L17OmO3S5OTQQM1KPnj7t68rYWUjTkDIEYpmpS/APJklFohvJ4QQAmqsiBSS8J
SoruRb5z8vJJhUVt1kiB/2LQ6EG5Bw4XGzZI2CyhAeSqc3L6G60TbddRb8KtGGg19L7Ro/Phk+cu
HRQ3EzzbnKNHHr58+7LOdmetCxcLYGqWNStPXrp05+BxMqPmSQVCo+TOpWtXWxI6U0BJ+IhaE1Jd
u0jNJTkDwYrfv8ICC2LVK5wbGYflhWTs+B+upKOgZFIh6eDjDz5SyUSTQFiYtEZKnuwjjzrhxKTL
TJ5BpuGGHAoUEAA7
}

#===============================================================================

    image create photo saveAsCvsImage\
        -format gif\
        -data {
R0lGODlhFAAUAOfQAF9GAmJIAFBKRG1SD2BTPl5aWFxcVGBbWn9bAIBcAGJdXIFdAYJeAn9gAoNf
A4hiAGVkXG9oYY1sAG9uZr6UAJ2TdaGWeJyZi8+dANCeANGfANShAL6iOdShBauhgtWiANGkAL6j
QtikAMClQ9mlAMumJcGmRMqmL9qmALymXsynJsunMMSoP82oJ9epAMOoRtyoALOpd96pAd+qBMqs
M6uprcWrUMmsO+GrANCrNMutNNytBeKsAMyuNcmtS7ysfOOtAN2uCM6vLbCtn66ssOSuAN6vC9av
JuCwAOWvALmuj9+wDeGxAOewALqvkOKyAMWwbdqyHrawnOixAOOzAOmyAM2yV+W0AL2zgN20Iea1
AOq0Ar2zk961Iue2A+y1Bd+2JOm3AO22ALu1oei4Bu+3AOq5APC4AOu6APG5AOy7ANS5XfK6ALq4
vMm5iMC5pe68ALW6vfO7ALu5ve+9ALm7uPC+APG/ANq9WvPAAcS+qvTBBMC/tt3AXfbCAPXCCPfD
APjEAMjCrvnFAPTHD8LEwfzHAMXFvM3GsvjKF8vIucnIv/vNANHIrsfJxvzOBMvKwdDKtcbMzsrM
yc3Mw9LMt8fNz87NxMvOys/OxdDPx83S1dDSz9HT0NLU0dPV0tbU2N7Vu9TW09fV2dXX1NnX29vY
3Nja1tzZ3t3a39fc397b4Nvd2tne4drf4uDe4tvg497g3d/h3uDi3+Hk4OXk2+Dl6OPl4eTm4+Xn
5OPo6+fp5urp4Onr6Obs7u3s4+ft7+rv8u3v6+7w7fHw5uzx9PDy7+7z9vHz8O/19/f59vX6/fj6
9/n7+Pf9//7//P//////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8J/NeoUqVIiATpeTNGypCBA2fAaKHoUiZNlyhBWnSI
Tx0hdu4kEMhEDZsKHOSwceOLWbA4WQIFemSIgUARHU78UtbLESZMkyZ9imWqRxo4CAQ2WXpjjRUb
IUKYeBHCRZEmdAKN/IcBwwlizYx1+vTJE6dTskzRoABCgkAUIkrUEnaLkydPnTiJYjVKBx06W4sI
Hrz0iuEwcODQsZNnq+EqSnxUCROjEClgm8Dc+ZMokM2BDwgUOKAgwgQIBgQMQICgAYCBVzCsELbM
WbJkxYDpskWrKBMZA0XIBhsW2bBdt2jRUtXjShgHb0Wo4IUM2S7kt2JpN5VD8VYYKEp5yPKl65Wr
VqtMqTIFyq9IgUVkzNgRxIgRJk8MG/ai+P2/JkUgIVgTU1RRxRlnJLbYHXs41kQVXDgBRQoX1DCH
JG0cgRghnglk2BkesHBGGliQ0kszlnSxRyCMDAKdQDDIYcEPePQRyjPHwEJEFDI90kQAEAUppJAB
AQA7
}

#===============================================================================

    image create photo saveExitImage\
        -format gif\
        -data {
R0lGODlhFAAUAOf/AAA3fAA4fQA5fgA3nwI4oBY3fgA7oQA9owBAphI/hRQ9nx5ERgNDox9FRgtF
pQxUIABKqQBKsRhLbRRHqABNrBVJnAROrQxPsEJJWxVSrANZshpUrhNlGwdcoQBtEhxVsAtbtAJu
EwByACJYsxZqJxJdtgBhyBVdtwBjuwBiyUpZUxZfshheuARjylVWXwRlvgBlyhpfuQBmyxxguglk
yxthtFhZYgd5FB9itg55CA1nwAB8FzVepw5ouhF0QTZfqC1iqiNkuFtcZQB/GhFrsC5jqyVluRVq
vC9krCZmuhdrvV5fZxpqxChnuwVxyipovDRnrxxtwGJiax9uwSFvwiNvwyVwxACPBxZ1zidxxWdn
cClyxhh3ySpzxxt4ywCVAB15zCp3vSx4vi93xSN7zgWdADZ8ywmeACmAzU55sTh9zCuBzkx7qw2f
AFN6pi2CzxCgADt/zkh+tFV8qEl/tU9+r0qAtlh/qxmjBEOI0F6FshitADGhQkiM1DySzHyIlWaM
uW+LrUOge4CMmSi0EDSxDWqQvTayD06flEOsRjK0K1WhkHyUsUWvSDy3F4uTmkG5BoaVqIqVoka0
PUyyRHGbwYaZsVqsfHSexUq4QVS1VlG+I0nBJoyft2O3UlXCJ5ahr1q/UJykrGi9V4yovp2lrZqm
s2LAWVvHLqKrs2nNPnDHZ6iwuG7QObKwtKy0vHnTRrK3urC4wJDIhn/VWLa7vrC8yoXRf7S9xbjA
yJDTgrvAwrnByZHUg7rCyr7DxafQpMHGycPIy8TJzMfJxsXKzcbMzsrMycbO1tDN0c/RztDSz9HT
0LHioNLU0bLjodPV0tXX1NbY1d3Y1t7Z2L3oruDa2drc2eHb2tvd2tne4dze293f3ODe4tvg497g
3d/h3ubh3+Hk4Ojj4uHm6eTm4+Xn5OPo6+zm5efp5tvu2eXq7enr6Obs7vDr6eXv6ufw6/Dt8u3v
6/Xv7u/x7vDy7/Hz8PL08fjz8fz29fb49Pj69/n7+P78//7//P///yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8J/GfLl69cuGS9YpWqlKiBAmlksACF17BhxooJC/Zr
V61YdrysCSDwiBUnf9xkcUIq3iw8odQ1a/NlyIN/NBggAHJOHztix4Ieg/ZtGp0tZEjSmIEjRhpD
gPTMYbOIVitUmw6tOkUC5wECPNrxq8cMGjRmy6SBw1anA5EEOCFMKOJNnrhlzpgxUwYtWzQ6XuIo
HQECxIkTLFAESaJEDCJNmRIJ8qM0yRMdoPRMmRIp2aRRwA716veszQ6IBTC4sCFEipYlKjiIuOHh
QYOBEcCu28cP37157tCFC7dNjpIecGkoOBCWHz969eSlEyduLZ0pY5Q6cACEnL166dKXmRP3jVtR
Ol3iAPgHwwKFItrYpTPPbdu0a9aihURDEsaGDRqsUAMOQfRwRBRVWBFHH3mQMRJOhyHGwgwv6PBE
GJfQAssmjuzBhwTsGWHEDKaAwkggj7jiiSqQcELILfnokgNOUUzBhCR3VFFFJ91Qkok48PRTTRtX
hCBQBUlgMYgllWCCjD/wJFKGIkQO4cNtEGWpZZYBAQA7
}

#===============================================================================

    image create photo A_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKECAB8Ztf///4O/CYO/CSH5BAEKAAIALAAAAAAUABQAAAJHlI+py40Bg0uggjCP
rSGbGlRQZgVWkFmCFWRVYFSQYwWGFThWZAVBswkCAgxhMMCwKCo+hSWgsAQUloDCElBYFhaP9wtW
FAAAOw==
}

#===============================================================================

    image create photo B_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKECAB8Ztf///4O/CYO/CSH5BAEKAAIALAAAAAAUABQAAAJElI+pyx0PYwO02ses
pm/VgFjBUgVJFSxVkFRMFT1UwGzas9jao1RBYgkoKgFFJaCoBBSVgKISe1QWOgvDZmlot9yutgAA
Ow==
}
#===============================================================================

    image create photo C_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKECAB8Ztf///4O/CYO/CSH5BAEKAAIALAAAAAAUABMAAAI8lI+py30Bozug2tis
tnBppAWLpViLFUyJFaiIFbiHFciGFTDBYkEKEFFYIAjNQhMJaBqbjaqpiEqn1GgBADs=
}

#===============================================================================

    image create photo closeImage\
        -format gif\
        -data {
R0lGODlhFAAUAOfhAEUBAUkAA0sAAEwAAE4AAU8BAlACAFACA1EDAFIEAFMFAFsDAFQGAV0FAFcI
AF4HAowAAJ8AAKEAAqQBAK0AAa4AAqUEAJsHALADAKYGALEGAKcJALwFArIJAL0IAL0IA7MMALUO
AMAOALYRALcTAMERAMsOAsITAMwRA8QVAM4TAMUXAMUXCc8VAL0cDtAYANoWA78eBdsYANMcAMEh
CN0aANQdAMwiD8UlC9chAdgjAtkkBOMjAMorEOUlAO8kAN0pB/AmAM8wFOkqBNEzHdsyEt81C942
FvAzDeE4GOo3FOI5Gfw0Cf02C/Y5Ev83DN4/IOg+FPo9CehAJdpELfI/GvNAEvs+F91GLu1DIf9C
APhECf9DAvZDHutJGf9EEvhFIPVKCf5KAuRNNO5NK/1KJOdPNtZXN/9SBf5SFO5VLu1VOuhYOdZd
QOxZJ/JYMP9VKPFYN/NZOPRaOf5aIO5dRP9cK/FfQPtfMO1jP/5hI/dlSvFnSf5oLf9pJ/1tHfNw
VP9wOPVxT/92I/l3MdF9cfd3PvR3V/95Pfd5WfeBY/mBXv+EOviDavuHR+eJc9uNfviHZv2GZ/mI
Z/6NPfqLb/iPceqTgOWVhvqRcv6VT/qXdvuYd/+cU+ifjdejo/qef/ufgPOhi/qlg/umhP6ohvKq
nfaqkvOrnvmrjfusiPGvoN+4s+i+tP2/junGufbDtOjHwPTIt97OyfXJuNbQz9nT0v3RwP/Swf3S
x/DWzejY0+Da2drc2f/Uydvd2t3f3N7g3d/h3vPc2P7azdzi5ODi3+Hk4OPl4eTm4+Xn5OPo6+bo
5efp5ujq5+nr6PHs6u3v6+7w7e/x7vHz8PL08fr18/b49P339vf59vX6/fj69/n7+Pr8+fv9+vz/
+/7//IO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CSH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAAAj+AP8JHEiwoEE8pVSNCsUp06RFiQTtubPGDBUcA0u5osSI
kBs/euik+XLFCZIhQG4MTNVp0J82n7ygEcOlCapGQXjISPFA4ChNf87YEsbKChcppq5Zk8QDRokG
AkE5alML2DFmrbqsusbNG7hKO0osELjJUKFewY41izbs2jZv4MDhMvLBgUBLiMJAOoasWTRq17jF
JRblBQkGAiMFQrMFEzNn0qhl8wbOVxYdL0YoEKiojxguUmI9m1Ytmzdsb2TMQNFBgcBDdrg08bTM
mbRq27yByzXlxYoOBQQCgtPk0jFkzqJRy9Ytri8oJSoQEMinzKNfwZA1iwbtGre44HCLEdlAQGAd
MHFmBTvGTNccWNu6xRUVwwIBgWyqBInDq9guNTIsQYs23ZzCAggWECDQGErwwEMer5ABwwwvFCGL
KCyM0IEEBAhExREyyKBDEjO8gMIKJwhBwwgdbHBBAAK50EMKJ5QgwgcjgNBBBRtsYIEEEkBQkAIK
JHBAAQQQIEAATDIJgEFQRilQQAA7
}

#===============================================================================

    image create photo refreshImage\
        -format gif\
        -data {
R0lGODlhFAAUAOeXAAEZPQIdRAEeUAceSAIkVQAoYgA3Yw82bgo3dgk6ZQM8hwg/gQRFegtEiQ9G
egZKhQxKhQVMqw9OlwBUlB9RlQ9VoiZTkAlcww9guw5itxlgrhNishZntxZotRdpvQ1vwxxtvyZr
vxJw1BtwyCZxtyZxxCFyy0FsqyNzwwV71ipyyR12ySZ2wyN5x0Z0tw2B30d1tQ6E5hyF7DWCyyGF
6y2G4SKM8z6JziaQ8CGR+SuP8UaK2DaP5CeT+SyW/C6X+1yQzzmZ4Dib4Tqb4TSa/Tmb+jid/jyd
+Tyf/0Gf+Vab4z6g/0Sf+Eeg90ih9kKi/0mh9l2d5UWj/E2k+E6k+Eml/1qj6FCl+FWl70yn/1in
5VCp/1Gp/1+n72Wn6Viq+WOp61es/3Gn5GSs71yu/2ut8GWw92Kx/2+y62i0/3Gz8Wy1/XC19Xm3
8HK5/nK5/3649Xy69Hi7/Hy8+n6+/4TA+ILB/4PB/YXB+4jB+YXC/4nD/IrF/4vF/ovF/5DH/5HI
/5LI/5LJ/pPJ/5XK/5rM/5zN+5vN/53O/57P/5/P/6DQ/6PR/6bS/6jT/6nU/6vU/6vV/6rW/6/X
/7nc/r7f/cXi////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjhAP8JHEiwoMF/Q4QYNOElTyFGjxwBOQiiSZUnSHTQkCEi
wEGBEwp2mEImTRcFO+RQENhmESJCfqx8nPkvRo4eP4wsqQLFA82PSvj8GRQIjgCBWixBWjTojhkS
AwsgsHACxoCBc8BAGPPmzJUNPz8ukNCAQFiBL3AckeKER4afKT4wMPBgRZIsXKhoEKjiLIo1dPRE
wTPnwNkQgw4pSiRmYJBKlAzVYYOlxb8SZfYskjQpkouBaCY1QgToRoKzcQSp6WPHDYuzMxz84/Al
zBYmIwZeiPCzQo0iRHzYwADg7NmAADs=
}

#===============================================================================

    image create photo aboutImage\
        -format gif\
        -data {
R0lGODlhFAAUAOehAAE9pApoygtoygBt0wFt0wB64QF74QCI7gCI7zyAzj2Bzg6M8GGDwkmJ0WGE
w4KCjoyMnI6OoI+Po5CQo5KSpXSg2Iag1J6etomi1p+ft6GhuqOjuqWlu6WlvKiowKiowaioxKmp
xIyw36urx6ysw368/LOz1IK+/ITA/J275YTB/Lm52Ki+5KLF9sHB2sHB3LTH6K7J+6bM9sXF5MbG
5sbG8rXM9MjI5cjI6rnN8snJ68nJ+svL6crK+sLO68zM587O6brT9MPQ/s3N/87O9c/P7s/P8M/P
8c7O/7jV+8TT88jT67/V8tHR8NDQ/tDQ/9LS6tHR/9LS/tLS/9PT9dTU8NTU8tPT/9TU/9XV/tXV
/9bW+9bW/cza9NbW/8/a9NfX/9jY/9nZ/9ra9dra/9De/tvb/Nvb/tvb/9nc/tzc99zc/93d/97e
897e/9/f/N/f/+Dg/+Hh++Hh/+Li9eLi9+Li/+Pj/+Tk/OTk/+Xl/eXl/+Hn+ebm/ebm/+fn/+jo
++jo/+np+Orq/+vr/+vt/uzt/e3t++3t/+7u++7u/O7u/+/v/O/v/e/v//Dw//Hx//Ly/vLy//Py
//Pz/fPz//Tz/vT0//b3/ff3/ff3//j4//r6//v6//v7//z8//39////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JHEiwoEFFnjRVkiRpEpMAAnLcgYPGyxMpMwwalGCl
yAaNkUCB+uSJkwUAADAg+nOHDRsjBV/QIRSojAoUJ0oImTLkzQeDWfps4uSpUyZMmyANwnNjBMFG
Ij9pqsQnhYgKXwLlgUNGCxgcAnUwggTp0aNCMgoYaJFGDJYoZ2hoHMjBQwcQTnoQcTHX4IMLEPoO
3CIH0CFGiQS1AbJCIxdJn0B98rTEAQMfiwLlmWOFxEA9n0B98rTpkiUYLAwN2jNnjRc3JgRSAvVp
UyVJXRooSKDEjx02Ya5MOSKwTiWGZB8FGUDARpw1YKYMMRNi4I9GjxwhSrIAwYEFMbQmTMnTRIJG
F1DUxHFDxssUJDvGUBBMcAKVGlUi0CeogUeG/QD+ExAAOw==
}

#===============================================================================

    image create photo stopImage\
        -format gif\
        -data {
R0lGODlhFAAUAOftAJ8AAKEAAqIAAKwAAa4AAqUEALIJAL0IALMMALYRAMAOBQA8oswQAMQVAABC
ohQ9nwdEpAtFpQBJrwBKqQBKsBFGpwBLqgBNrN8eAAROrQhOr+AgCQxPsB1LrBNRshVSrABYtxhT
tARZuBpUrgdaswBcwQBdwiBXshBbuw9ctQBgvwBhuRJdtgBiuiBcnBVdt8s2ItwzEwBkvMw3I900
HQRlvhpfuR9huzFfmxxkqh9itg1nwBFowSNjviNkuBJqthRpwiVluSRmtCZmuhdqwxpqxChnuyho
thpsvxptuSpovClptxxtwCxpvitquC1rudVHMuREJCFvwg90xiNvwzZtqRJ1xyVwxNdKMxV2yDdw
pTlvqylyxhh3yfJIJf5KAkRxpyt2wy12xDd0vCx4vudPL/9LEi93xcJXUjl1vTB4xjp2vi96wSN9
yTJ5xyV+ykR4tEZ6tz59uUZ8svZVODmByO5cKexbPEqAtvVbOu5dPj6Ey+xgMM1mWDWJ0NdnVlCF
vGCHtN9sSvhmRWGItdduX1yKvN5wS2SKt2WLuGaMufFuTJeGmtV6aoWRnvV4WOx6Z4qVovx/LtmD
cZKXmZabnZecnvOGcNeOd4+iupOjtZijsfGQdZykrJemudmYg56mrqGmqZinupmou5qpvNubjJeq
w/OYee2af6mqtJqtxq2vrJ2xyZ6yyqyxs5+zy6m0wqK1zqO2z7zBw8HDv+LBu8nHy8fJxsnO0OrJ
wuPMydDSz87T1tHT0NLU0dPV0uLSzdTW09XX1OPUztLY2tbY1d3Y1vvRxtja1tnb19rc2djd4Nvd
2tze293f3N7g3d/h3uDi393j5eHk4Pnf1uPl4frg1+Tm4+Ln6uXn5OXq7e7o5+jq5+nr6Obs7v/o
5fvr5vzs5+7w7e/x7vfx8PL08fP18vf59vj69/n7+P/6+fr8+fv9+v//////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JHEiwoEEQHj6Ymlat4TRozpIF86XpTJsmAotQoQIm
0pQscn6Ju5QHmDZy7L5hKfCvgwMIsc6lmwbtWbNkyKA5GzVFTBCBN2y00HHkyBInT9aUknSIz5dB
dDA0+EdhwQNZ6NYlS4ZMWLBf0J6R+uFih0APEyywEjcO2rNnzZIhc5ZMlBg1QwSiOEEixYsXNmoE
GULljJs3dfb4ESOQx5AhW2CNSTNn1a1Tdmp1K7fuWAwEA2vgsFSpUypctv5siEKDAZQZBAL8K0GB
Qits3rxpwyZtGTFeuDIVKQJCIIUHDmShW9ewGjRnyaY9I5UkxxCBGSBUeFXOXDJkyISkBfv1rJko
LmeGCAxxIYMqbtx++fLVa9euZMg8dXEzRKCIESPAEQghhiCSSCKKHKgIIGq80YRAKvz1wgot1BDE
EFQw8gkmkzRSSB9oCNSDDzVUMYsroFBCSSioCGIMMI+AE04ZB/wDBBJMgLEJFVfEQUsznJixyDbm
qKMHAwT8UwITVmjhCBls4FHNOZB4oUsud1hDDQwBGGSQAgkYMEABBQTwT0AAOw==
}

#===============================================================================

    image create photo copyImage\
        -format gif\
        -data {
R0lGODlhFAAUAOfOADoyV1dKeFhLeVtJkVlMelxRql5UiGFUg19ViWVUimRXhmVYh2ZZiGNXsmda
iWhbimVZtHZdo1pphmdyin5spGJ2mYFsq3ptt297n3R8qHKBn3CDp3SDoXGEqHaFo4F90neGpHmI
poKGrXqJp46Du32Mq3+OrYCProGQr4OPtH6RtYSQtn+St4WRt5mKyY2M24aSuIuSs4eTuZyNzKKO
yZ2RvZ6PzqOPyqSQy6WRzKCUzaeTzo6dvaaWvZKdt6aWyqeXvqiYv6mZwJWguqaaxqqawaqaznir
0aqeynms0qmg0pmou6qix6ui1Juqvayj1q6l2LGl0rOm05evzZiwzq+qyLWo1Zmxz6+q1Zuy0LGt
y7Gs15yz0amxxoa537Kt2Z200qqyx6S0x7Ou2reu1KK23KO33Z253bqx17uy2Ki42Ka536q52cC0
1au62r212ri328G11ru31qy726283K690bq7xa693b652MG50q++37+62bO+2bS/2sG827XA27bB
3LnE0rvD2KHK5bzE2cHF1b/G3MDH3aXO6bfK5L7K2LjM5cjI38DM2rnN5sfL28HN27rO57vP6LzQ
6dLO4MbS4MPT59PP4cTU6NTQ4sfW6snY7MrZ7dPX583Z587a6Mvb7s/b6szc8Nba6tDd69jc7NLe
7Nnd7dPf7dre7tTg7t3e6ODe4tXh797f6eHf49bi8N/g6tni6uLg5OPh5eLi7eXi5t/k5uPj7ubj
6ODl6OPl4eTl7+Xu9+zs9+jw+erz+/Px9ez1/fD2+PL3+fP4+/T5/PX6/fb7/vz6/vf9//j+//z/
+/7//P//////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JFBiBSJEiQoIA6UFh4EAUyng9YnSIECA+c9hMQgXj
Bw4rexz849DLE6A/ffTQcbPmTKJNGAQQEBAAwD8VyJrpXIbsmKIjTmzZqlKDxIUBAkcQc3XIkMU+
dzJKMpXixownaRQI7NBhw4YMXcLYuSV0VpUPDRyyUKZzp7JClQYdEYHEyI4vfh78M3HM16pTpUZ1
2qQJEypTMHTYkAJnwT8QwEoREgQIakYzjkDJiPJkzBgD/yqAGQ2Gi+ksqKlMkeCwtUALr3TpEvqK
FZMCrVUQM8a7GLFhYpbssmV2ywsIA9e2baYMWSNEXnjk2ROHTBs5CW4qW9Y8mbFisiBxBaozxEcm
Spf8iDyhLBiuWrFSBea0CRYqGR6t4GHwr4SxWE09dQcdGlGVAw1RvKFVCMKs0hRlfNCRUSSgpDCD
C0qggcA/HvzyCSCVRcWGGWUswkkMWEgBRRMH/KNBK6qYIqMpoYDCyY2WTODajjy2FhAAOw==
}

#===============================================================================

    image create photo A_ch_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKUtAB4ZtB8ZtR4fqx4gqQtZBgxZBgxaBgxbBh9SaiVPehmLDBiNCx+MHBqQDR2S
Dh6VDiGVESKVEiWbEiScES+dIS6hHD6ZSS+jGj+aSSmoEyapEjKlITKuGDGvGT+pODqtKDivKDex
GzywLD2yKEKwMj6yKz+zKkC1I0ezNk26MmC9VLLcr/3+/f//////////////////////////////
/////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5
BAEKAD8ALAAAAAAUABQAQAZywJ9wSCwai4FAS5hsLY/JAFHC6XhAjMJxGG1uud1wgPVDmSJfp/NL
jLbc7J/bOYd6f5/U5TdIWEoOcUMLCoKGX11Pgk1NiohJcnePSkySdmJ3JBttkEUAAisqIxAHYJQ/
FSchEwgYIhQGhg8ZGg0Eh2xBADs=
}

#===============================================================================

    image create photo B_ch_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKUyAB4Zsx8ZtR4crx4fqx0tlR9BgSBGfgtZBgxZBgxaBgxbBh9SaiVPeiJuSiJ0
QSl0TRmLDBiNCxqQDR2SDh6VDh+VESGVESKVEiCWET6ZST+aSSmoEyapEjKlIUGdSTGoHjCrHDar
IT+pODivKDuwKjywLD+wJz6yKUKwMj+zKlG7NmC9UWy+XWzBXq/bq8nix+/37vX69f//////////
/////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5
BAEKAD8ALAAAAAAUABQAQAZ3wJ9wSCwah4GkbMlUHn/JKKHxAYlGFcQxyuUut85iAFBYpS5Fppr5
hIaRb2J3HpDFjNFlS8V6wRgZJBNtRREQhIhtdHkyT3lyj3hxbgGOi0qNknViSQIuKB2Qm0UDBh4n
FgqiSQ8mIQ4LGiUYCYk/FBscEge2iEEAOw==
}

#===============================================================================

    image create photo C_ch_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKUwAB4ZtB8ZtR4fqx4gqR0tlRwxjiBGfgtZBgxZBgxaBgxbBh9SaiVPeiJuSiJ0
QSl0TRmLDBiNCxqQDR2SDh6VDh+VESGVESKVEiCWET6ZST+aSSmoEyapEjKlIUGdSTGoHjCrHDar
ITmxJz+wJzyyKT2yKEKwMj2zKj+zKkKzMFG7NmC9UWy+XWzBXrbdtP3+/f//////////////////
/////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5
BAEKAD8ALAAAAAAUABMAQAZuwJ9wSCwahYEk7MgsJgmNDyglqiCYyaw2AFs6lV5i4OVaoS7Mrjp8
zBrdb2UTm4W1VKzCgJEhTeZEERCAhHNbXF10SWJ1cVyFQ42QP5JGXiYdjIhEAAIGHiUWCl9JDyMh
DgsaJxgJhRQbHBIHREEAOw==
}

#===============================================================================

    image create photo prevConflImage\
        -format gif\
        -data {
R0lGODlhFAAUAOegAEsKAEkLAE4KAFsHAFUJAFkMAVkOAV0PAZIIAZcKAYwPBJoMAJUOBJ8MAaQO
AYoWBrYOAJEZCLkOAJAaCbQRAb4PAJgaB5EcCJgaCsQTApIkDpcjD7MdA88WApUnENQZAdgaALgn
BbknBcUkA74mBLooBcUoA8ooBMspBb8tB8ksBsssBMQuBsEvCM4sBdA3C8w5DtQ9CuBBCd5DCthG
DdxFDNtGDdpIDeBGF9lJDthLD+FIFtZMEddMENVNENNPEtVPEuJLF9FTFeRPGPpLDM1YF+FRJOdR
GetRGuhSGfpODeJTJudTGexTFONUJuJVJvVSEPpRDv9QD+NWKOxWE/9RDu9WE/pUEP9UD/9VD/pX
Ef9XEfpZE/BcFf9YEf9YEv9ZEvRcFvJdGP9aE/RdF/JeF/pcFOxgF/9bE/9bHfRfGP9dFP9dFf9d
FvpfFv9eFOpkGf9gFf9gFv9hFv9hGP9jF+tpHP9kF/9lGP9lGv9mGP9nGf9oGv9oHP9nK/5pG/9p
Gv9pG/9rG/9rHf9sHP9uHP9uIP9vHf9wH/9xHv9yHvp0IP90H/91IP90PP54Iv94Iv95Ivt6MP97
Jv9/L/qAPv+DOP2JR/+LXP+NXf+RYP+VY/+ZZ/+daf+gbf+hbP//////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjmAP8JHEiwoEGBJMpMomQJESFAeOrEsUJDBIGD/3ZgcuQn
jRQiMh5gJOgizCI7QlocGDkwCac8ctig0ZKjAUuCJlYEuCkQhZhHjRIV+nMGSAgABkF86JABiadB
eu7IMeODwgIJFSAcHKKpDZgtWKLUQHDTAgMMGzxomBCBJ8EWbgmu4FGEhQG3J8hAYpQIzo8UAkaq
UBOJkaJDgvjg6dKjRIGCI5pIqnTpk6FAe+q4oQLFRgwOAw4y6dSnzpw3XHQ4uHlkE501Y75cuZHg
ZpBMXrJgqaJkhoKbMJ5McbLECI4XF+LeDAgAOw==
}

#===============================================================================

    image create photo nextConflImage\
        -format gif\
        -data {
R0lGODlhFAAUAOegAEsKAEkLAE4KAFsHAFUJAFkMAVkOAV0PAZIIAZcKAYwPBJoMAJUOBJ8MAaQO
AYoWBrYOAJEZCLkOAJAaCbQRAb4PAJgaB5EcCJgaCsQTApIkDpcjD7MdA88WApUnENQZAdgaALgn
BbknBcUkA74mBLooBcUoA8ooBMspBb8tB8ksBsssBMQuBsEvCM4sBdA3C8w5DtQ9CuBBCd5DCthG
DdxFDNtGDdpIDeBGF9lJDthLD+FIFtZMEddMENVNENNPEtVPEuJLF9FTFeRPGPpLDM1YF+FRJOdR
GetRGuhSGfpODeJTJudTGexTFONUJuJVJvVSEPpRDv9QD+NWKOxWE/9RDu9WE/pUEP9UD/9VD/pX
Ef9XEfpZE/BcFf9YEf9YEv9ZEvRcFvJdGP9aE/RdF/JeF/pcFOxgF/9bE/9bHfRfGP9dFP9dFf9d
FvpfFv9eFOpkGf9gFf9gFv9hFv9hGP9jF+tpHP9kF/9lGP9lGv9mGP9nGf9oGv9oHP9nK/5pG/9p
Gv9pG/9rG/9rHf9sHP9uHP9uIP9vHf9wH/9xHv9yHvp0IP90H/91IP90PP54Iv94Iv95Ivt6MP97
Jv9/L/qAPv+DOP2JR/+LXP+NXf+RYP+VY/+ZZ/+daf+gbf+hbP//////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH5BAEKAP8ALAAAAAAUABQA
QAjmAP8JHEiwoMGCTDr1qTPnDRcdDg4aXMGjCAsDEgsGyeQlC5YqSmYoyKhCTSRGig4J4oOnS48S
BTLCeDLFyRIjOF5cyCjwyCY6a8Z8uXIjwcERTSRVuvTJUKA9ddxQgWIjBocBB0+QgcQoEZwfKQTw
LNhiLEELDDBs8KBhQgSzOzA58pNGChEZD8YO0dQGzBYsUWogGJuEUx45bNBoydHgIIgPHTIg8TRI
zx05ZnxQWCChAgSCJMpMomQJESFAeOrEsUJDBIGDKMQ8apSo0J8zQEIAGOsizCI7QlocMDvQxIoA
xJP/CwgAOw==
}

    image create photo helpImage\
        -format gif\
        -data {
R0lGODlhFAAUAOfqACEhISMjIyQkJDg4OD4+PkNDQ0pKSlNTU1RUVFpaWltbW11dXWBgYGhoaGlp
aXd3d3p6ehekCxqlDRymDR2nDh6nDn9/fyOmEB6oDh+oDyCoDymmEiKpECSpEIKCgiOqET+gIiWr
ESarEiarFCisE4aGhiuuFiyuFS2uFS2vFi6vFjStGy+wFjCwFkSoLoqKijWtKzWwGTKxGDauLDWx
GTOyGTSyGTixHDazGlijVY+Pj0GxJTu0HTy0ImahZT21HWGkXJGRkT22HT23Hj+3HkG3JUqzO0K5
IZWVlWaqVUS6IU21PJeXl0q7Jki8I5mZmZmZmkm9JEm+I121S5ybnFa6OE6/JpycnGS0VFO+Kk/A
Jl+7Mp6enmC5SlHBJ3CyYp+fn1PCKWu2W6CgoG62W2y2ZFXDKmO/NGW8TVbEKlfEK3S2bl7DMG65
ZlzFL6Cmn6WlpVzHLWLFMl3HLne5cXO7bmHHMl/IL3u5dGDIL366YmPHMWLIL2rFPmjHOqmpqWnI
OmXKM461i368d2XLMmbLM4u4iGXMMmbMM6iup33DX426iq2trYDEYJO6kJW9gY3AgJu6lrGxsbKy
srKys7W0tYPMapfDjbS3s4/Jcp7CjJfEjobOZbi3uKTBno7Nb6TEoJ7Ijru7u53KjpHScZHSd6XJ
mb6+vqrIpabLm67IqKnLnp7Qk8HBwcLCwqzMoMPDw63PobLNrcfHx8DOvLrRsLjSscnMyczMzNDP
0NHQ0cbVwrncqdHR0cPV09PT08jYwtPU09TU1M7Xysraw9bW1tfW18/az9LczsrhwNPb4dLgy93d
3d7e3t/f3+Dg4OHh4dnl1eHi4dPqyOPj4+Tk5OXl5ebm5uno/+bs5ubt6ezs7Ozt7O7u7vHx8fLy
8vLz8vT1+ff39/f3/vn4+fv7/fz8//39//7+/v7+////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JHDhwFsGDAq+9ikMIkUNEcnid0+ZCBYdBnRoc5FIJ
UyQ8ZdYIehMEwgCEzsTV8sOnD6dSlqoI6bHJmCSCroKhUeIkShMyX7DQUCGCAoxELwIcfCYOHLJY
o1LtkgatFcJm3BodKpRpmaZH0c6Fm8LCyC1GA5mZ0qJmzh02yczZAsFDBokJdP4sGDgJ16UaNlYA
8ZHjQoUIdahYEIBwoAEFCxAQAND4YDFr3b5520at183K18gRU+QmjRcpR7rIYgbr4K9vwAAh+oRO
ne1yrG6kQJWrxMBqw+w4PLNlzx496caJaTEClKgD/05RC6UmT8NApKahy5YkxgkNbShSORAojFYU
K2HMZFl1DNIPHCg6SHAEpoBAOLpUFRlCZIcybL5sIEIGESzyBAMHSdKKJ0uYEMIHGEwwgyFQeHBS
Yw8gMQYYVzChgwUJKFXZiI0FBAA7
}

    image create photo markImage\
        -format gif\
        -data {
R0lGODlhFAAUAMZbAAAbAAAdAAAeAAZXAwVeAg96Bw18Bg58Bg99Bw5+Bw9+BxB/CAyBBg6BBw+C
CA6EBwmKAwmKBBGICA+KBxKKCQ2NBw6NCA6OCA+OCA6PCBSOCheOCxeQCxaRCxeUDRmUDSGZEyOg
FiKlECGmEC6jHyOpESWpESSqESaqEierEierEyirEyesEyisEymsFCusFSmtFCqtFCqtFS+tFiyu
FSyuFi2vFS2vFi6vFjCwFzWxGjOyGTSyGT2vLDazGjezHzezIDu0HTm1HDy2HT23HkezNT+4H0G4
IEK5IEu7LUy+Kle7Rle7R1O9QVi7R1i8Rli8R1i/RVnARVnARlnAR1nASFrARl7BTV7CSm3IU3rP
YP//////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////yH+
EUNyZWF0ZWQgd2l0aCBHSU1QACH5BAEKAH8ALAAAAAAUABQAQAeWgH+Cg4SFhj1ZIIYXS1M0LQgC
hoMEA5OXmIIRUFhAG4MUOj47P1dNMiYJAZmsrYYVTlY2LguSHklIRkQdghlQUTEoBwCYDy8xKSUN
xK7Nzs+FFkUkzhhQUjguBa0VT1Y3KwurfyFaSkcfhBBQVDUqDsyDGkFDQjwcE0xVMCgKkpcSZuSw
EYPFCQP/WDEQMcJAPGgQWwUCADs=
}

    image create photo unmarkImage\
        -format gif\
        -data {
R0lGODlhFAAUAOeuACsAADMBAFAAAE0BAFUDAFwDAVkEAWsGAW4GAX4HAngKBIwHAZMIApUIAocN
BJMLA4sOBZ0LA64RBJ0WB7gPCqgVA6UXCLQVA68XBK0YDawbCaocCqwdCr8YCcYWDLMdCbseBM4Z
Ds0dD8weCb4jBcMhFMsgDrwkFdIhGM0mDMUtEc8rGtUqHcovENQsFNQvCMsxEdstCtEyENA0HuAy
DuQ2CuE2E+Y2CdU6FuU2EOk3DuY4Eu04C+o5C9s9Fds9Fu86DPI7DOg/FvM9DvQ9DtpCLPQ+DvRA
EPJAFvVAEOBEJ+VEGehEIdxGM+1FF+5FF+pGGvdDEvhDEuFJLPhFFflFFe1IG/lGFfVJGvpIF/tI
F/hJGeNNMPJLHPZKG/tKGvxKGf1LGvVNHvxMHP1NHPpOHedSMOlSMP1OHf5OHP5OHftPH+lTMPxQ
IP5QH+xUL/xRIO5ULf1RIfpSIv9RIPNUK/9SIfJWLf5UI/9UIv9UI/dWK/5VJP9WJP9XJf9XJv9Y
J/9YKP9ZKf9aKf9bKvBfOf9cK/FfOP9dLP9dLf9eLf9fLv9gL/9iMv9kM/9kNPlmOv9lNP9nN/9o
OP9pOf1qO/9qOv9rPP9sPP9tPf9uPvFxTPxvQf5wQP9wQf90Rf52SP92R/93Sf95S/98Tvx9UP9+
Uf+AUv+DVf2FWP+FWPiHX/+KXfmNZP//////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JHEiwoEGCJThlkvRo0aA5OBQY7PBlyxMYEAgyiNHj
BYgDBzepMgVqxsA3jPR4aWGAoJJKjhQRCoSnTZowWqpE0SHhYJNVqU4UDLFHDpIRBimUGvVJUxwz
kwzxsbLhoMApnRoS+mNnjI0HB5n8yUOnzBIOCXZQiZLESJAaFQoKsEq3IIuDIkwcRNGK1alCBD3c
GYTGyQeDRVCREgUpw78zkQCt+eHAKpdQnjBRkqQIkBgVA+qysfSIESE/XSzQXXHoUiNEg7iqCZMl
RwSDdRIJAtQHDhQhYLJckZKECI8LA138cUMGi48JAP41oHFkCJAbJAgQTCFDQwGDCzAHIAhQt/zA
gAA7
}
    image create photo markAllConflictImage\
        -format gif\
        -data {
R0lGODlhFAAUAOeZAAAIAAAJAAAKACMAACQAAAALACcAACkAACsAAC0AAC8AAAAOAAAPADQAAAAQ
AAARAD4AAEcAAEsAAE0AAFAAAFsAAGAAAGMAAHoAAIQAALMAALQAALUAALYAALkAALoAALsAALwA
AL0AAL4AAL8AAMEAAMIAAAI5AcMAAMYAAMgAAM8AANAAANMAAJAUAJ4QAKQPANkAANoAANsAAJwT
ANwAAJYVAJ0TAAJBAZMWAJwUAJsVAGEnAOkAAGcnAGsoAC07ATk/AH4rAARhAUpUAwpnBQloBAhp
BAlpBAppBQlqBQpqBQdzAwhzBAp5BU5mBgt7BQx+Bil5CCp6CCp6CSd7CCZ8CCx7Cil9Cg+ICSCF
DBiPCyGRDSCSDSKbDyyZFR2fDh2hDiOgFiGlECKmECSnESanEiOoESSoESaoEiepEyeqEyarEiyq
FSesEiisEymtFCqtFCutFCyuFS2uFTCtGC2vFi+wFzurKjKxGDawGzWzGjizHzm0Gzy2HT22HUK2
Jj+4H0K5IEK5IUe4NEa7Ik23OUy7OEy7OU27OU27Ok67OE67OU28OFC9Olm9RlzBSWPBUmPBU2PC
U2TCU2bEVWfEVHbMXHbNWoqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqK
uIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqK
uIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqK
uIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqK
uIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqK
uIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuCH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj5AP8JHEiwYEELPWKkkEBwgAcZOq5QamRnTRGCTtrcoRPH
zZkjDwyKHKlgRAwQGij8E4Op0CAvPjh4yGGlEqI4ZZQEGMlTYIMOGXoONPBBBgwpj/AMERjkiRAU
ICIg4FDDhkRGc9IkYTAwih4/ffZ00TJJ0ZsySLj2bAImjJGQQuPKFXmgxAwTF+QmCBHjBhEgAARi
aDHBIIKiO6ZYcnRny78KMVisQAFBIIENM2hQobRojpolCwQauvTlBwkRKmK8qBIpkZw1ShwMzAJI
UKA/XHi4wCLpEBw0SGQbhFJnTx4+kAi9IYMkdE8mZuCwGXNEwNx/OE4UEBoQADs=
}

    image create photo markAllImage\
        -format gif\
        -data {
R0lGODlhFAAUAMZbAAAbAAAdAAAeAAZXAwVeAg96Bw18Bg58Bg99Bw5+Bw9+BxB/CAyBBg6BBw+C
CA6EBwmKAwmKBBGICA+KBxKKCQ2NBw6NCA6OCA+OCA6PCBSOCheOCxeQCxaRCxeUDRmUDSGZEyOg
FiKlECGmEC6jHyOpESWpESSqESaqEierEierEyirEyesEyisEymsFCusFSmtFCqtFCqtFS+tFiyu
FSyuFi2vFS2vFi6vFjCwFzWxGjOyGTSyGT2vLDazGjezHzezIDu0HTm1HDy2HT23HkezNT+4H0G4
IEK5IEu7LUy+Kle7Rle7R1O9QVi7R1i8Rli8R1i/RVnARVnARlnAR1nASFrARl7BTV7CSm3IU3rP
YP//////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////yH+
EUNyZWF0ZWQgd2l0aCBHSU1QACH5BAEKAH8ALAAAAAAUABQAQAfRgH+Cg4SFFkUkgxpBQ0I8HBNM
VTAoChhQUjguBYQSMzk2MSwnBgKFp6h/FU9WNysLAYIhWkpHHwwiIwYQUFQ1Kg4AqcOXmZt/s7Uf
hLy+wIeJnZ+howarra+xgouNj5GTlabDf7i6wuPoghFQWEAb6apOVjYuC+I9WSCnF0tTNC0IxP3x
kASJESIdBGWAEiUGigPr2r0TREGHjx0/rjSRYSJBBXn07AnCB+LBixgpSjTg5w+gQIIGERIYsLDh
w3OFKl7MuLGjtmEmUarEmW5mukAAOw==
}

    image create photo prevUnresolvImage\
        -format gif\
        -data {
R0lGODlhFAAUAKU0AAACAAcAAAQHAqwAAa4AAqUEAMEAAMMAAMQAAMYBALwFAs0AA9AAAMcEANcA
ANsAAtIDAOQAAN8FAABzAACDAEOiGz6oIEinIDqvJ0WuJ0qyLEq6KWK2Ml26NVHBMGK9MFnHN1zI
L2TIOmjKM3LTPHXXQHTcO3LcRHXdPHPdRXbePXvjQnnjS3rkTHvlTXzmToDqUYHrUoPtVZPwaP//
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAAUABQAQAafwJ9w
SCwahZEIY9FIIFwslsp0wgiOBcfhoDiVShbAsciINGQx0HUsHEgYW1YKlRGziQyK/f6TmJswLy0s
G2tHBBEQcVIaAXcFD3AHJycmF3tjAZqbmnxFmJ59EjMhhnd+TTEvLh6mRRARCwsJCatyKROuELJM
TgeDKxwcHSMTRwNKcSkqdXdukimVl48OCwcGlCcVoEUFW1skIh9hoZ5BADs=
}

    image create photo nextUnresolvImage\
        -format gif\
        -data {
R0lGODlhFAAUAKU1AAACAAcAAAQHAp8AAKwAAa4AAqUEAMEAAMMAAMQAAMYBALwFAs0AA9AAAMcE
ANcAANsAAtIDAOQAAN8FAABzAACDAEOiGz6oIEinIDqvJ0WuJ0qyLEq6KWK2Ml26NVHBMGK9MFnH
N1zIL2TIOmjKM3LTPHXXQHTcO3LcRHXdPHPdRXbePXvjQnnjS3rkTHvlTXzmToDqUYHrUoPtVZPw
aP///////////////////////////////////////////yH5BAEKAD8ALAAAAAAUABQAAAacwJ9w
SCwajYGkMnkkXkCjEmKKMACawovJhFpMH1bsz4IqHxAM8BWLOZWnDUiY7VbBJ4R1U5NSte55Yhor
fnASgUhJGystfwgREgVKTiQeHR0sLS4ICQoODKARAkQZKCeMLS+dnw0SEqNFFCp+LzAKCqASok0c
mjAxng4SE7BNH7UynsMDYkIhMjPCDcXNIjQTxM1FFQ162kPe39pBADs=
}

    image create photo showHelpImage\
        -format gif\
        -data {
R0lGODlhFAAUAOfYAA1EpgFp0FhoggB64CJ0y0VtuF9vjlx3mwCK8mV2kGZ2kWZ3kmd3kgSL8mh4
k2l4lGl5k2l5lGp5lGp5lQ2P8V+CqHCAnnGDqnSEpWOLsWaNs3+Or02a3ICQsIGRsYGSs1+Z1IKS
s4OTtIOUtWyc13Kh1Y+gu4+kwX+pzZGlwaGkppKmwqOkpJSnw5WnxKOmqaSnqJmowJepxJepxZmp
xZupwaeoqZiqxYWu3Yau3pqrxpqrx52rw6mqq4Wx05at2Z+txKGuxaOvx6+vr6WxyIu53Kazype2
3Ki0y7C0uai1zau1yKq1zKq1zZC737S1taq2zaq2zqG43qu3zqu3z6C61LK4vLS4u7m4uK+7zrm8
vry8vLi+wrq+wbzAw7zCxsDDxZnM7cTExLHI4cXFxcfHx8jIyLLN4sTKzsLK2MrKysnLzMzMzMzM
zc3NzcbP1c3OzsPP48jP1b3R58PQ58/Pz7/S58HT6MvS38LU6NHS0sPU6cTV6dPT08XV6cbW6sfW
6tHV19XV1dbW1djY2NLa4NTa5dra2tzc3NXd6Nzd3d3d3N3d3d3d3tHh7t/f39vg5dvg69Tj793i
5dbk8Nrk7ODj5uPj4tjl8Nrm8uDl7eXl5d3n7tzn8t3o8d3o8t7o8tzp8ufn59/p8+Dp893q8+jo
6OHq8+Ds9Ovr6ujs8uTt9OTt9ejt8+Tu9ebu9O/v7+nx9/Dw8Orx+O/x8u3x+ezz+O3z+PDz9/Lz
9PLz9fPz8+70+fT09PD1+fH1+vH2+vP2+/b29vL3+/P3+/T4/PX4+/j4+PX5+/b5/Pf5/Pn5+ff6
/Pj6/Pj6/fr6+vn7/fv8/fz8/Pz9/v3+/v7+/v7+//7/////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP/9uzBChIgQHzx02IBBoMOH/5BUe3aoGrYfAAqkYrQF
0qgdEGOwcuVqVSEuSay88VQqlKMUEKdgm0lzGjRNWc4UqQDxX5BhazaZMjUmAIhBbMTAyCQDYpRq
1a5Zo2aTmSoUGXoKbEKzFyJGjwS1sQSM1ykaEIk407NMmrEcJI5cIlSnx6cbEHncsgVGjRwKCBr4
wKKCE6UWEA1MkMD4QQQIDhwwWKAggQCISpIp25ysGLFfiQ5oFUiF5sxq0Zq1qhJGg1Yopqsdy6UL
lyE8aZZYgMhkJqxHz4LRiWSqTKBbpEA+NBKtkbCZtaTEEYXIjRZQOiAKQQZH1i5aOAhFlFjURw2L
TjMgAvE1yQwjRU4GcEBDZsgXTC4g1pgV65WXJ110cYUNL1SCiiQrQGTCH38AAgiDfvCxRx532DHH
CaNl2FNAADs=
}

    image create photo infoImage\
        -format gif \
        -data {
R0lGODlhQAAwAOf/AAABAAIABQADBgAGEAQFEQIHFwAJHAANIgUXRAAbSAAaUwQeXgAhXwohWwAj
aAAlYwAlcQInYAApbQAqdQAteAwpfQAtfwEvgQIviQIvjwAzkgkwmAAzmQA1nA8zhwA2lgA4iwA4
nxU0lgA8lAY5oQg6mgA9mwo7lQA9qQA+pA07owBAmQBApgBCogBCqABCsARDnApEqwBHrABIrgBK
qgBKsABKsQBKtwBLsgBMswBNsgBNuAVNtABQrgBRvQBStwxPtg5QsABUuhBQtwBWvABWwwBXvhdS
ugRYvwBbxgpZwABcyQ1augBewwBfvgBfxABgxRJbwgBgxgBhzgBiyARjygBkzwBozQtlywBo1ABq
zwBq1wBr0BJmzRFowQBs0RVnzgBt0wBu1AFv1QNwzwBw3AZv1hxqyx5rzAxw1wB04EBmsBBx2A9y
0gB22wB33RRy2QB52AB53xhz2gB55gB64AB72ht03AJ74QB96Qh84hB95ACB7gCC5xN/3wCE6QCF
6xSB2hd/5gCG7ACI5wCI8wSI7h+C6R+D4weL4w6J8ACN+TuCyQCQ9SaH4QCR9xeL8gCS/wCT+QCT
/wCU/yyK5B6N9AOV+wCW/x2Q6VmDvACY/yKP9gCZ/g2W/DGO4gyX9laHxSOU5hOX/QCd/xeY/zaU
4SuY61yNyxme7wSk/yCc/CCe9zGa7leS0DWd8CWi9EGb6BKo/zeg7USd6yqk9l6Z1mib1D+l8kuk
7EOo9Tir/jet+Waj2lKp8Uet9D2w/Uuw912t6US1/0+z+Vmy81K1/EW5/o6pzUi6/4qr1Fa4/0q8
/1a7+2G4+lq+/5C01lzA/2W/+pW525i833fH/ZfB6ZfF5Y/H85bJ8KjI5ZvN9J3Q97DZ9cnV46fe
/q/d/rjh/dfg6N/h3ubg3+ri2uLk4cbq/+vl5OXn5Mzs/dXt/+jq5+/p6PLp4urs6ezu6/Pt7Pbu
5/Dy7/nx6ffx7/P18vr18/X39P727v/58v/5+Pn7+Pv9+v3//P///yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAgAAAAwADAAQAj+AP8JHEiwoMGDCBMq/BcFyatkx5YlSyZrlEVPkho1gmRo
0J8+gvTUkePGTRgdLRYKLAKFGLFmvCRdmjlTks0k0+LBgzdvnj18+xb9kVMSTpowYbhooRJFR4mD
OqDMmpVJ0J+rWK/26WNJGrhv4MKGDTdKUBqkX7SA6UKFChEgQ2JoAIBQRhw7bPLqzQtnSq927ODN
w8fPn2F1mLRQgfLkCRIdNXToCAEBgEqCDUqw4IFEiRIkRIj8GMKjNA/JklmE4KBAwOXLToicSVQL
GC9eunDVgvUqU5wnPHS8PujkysRk0VRZXE7qBTJy46KbM5fOHR1BeuSUhJMGqRYgLRL+/ojCy1ew
RpDSq1+vJts9fP0My8f0x80cNmnCfNECpguV0DFccJAObZziSB0IJqhgHWHk4IQy3rAjjjam7CHH
F1xoAUYXVEABxROl6VADBwYsdEIMYHChxYosagFGGIdEggkpmGDCyRxRPBHFDzrUUIMMNYSQwQDD
DQfAkQAUqWRCPzQJRBA9LDmcEmfokswxxhxjjDG8sAJKI4MA8ocggvSBCCF+KKHDClIi8cpx0ciy
HCkhrKFJKKGg4oorttiSRh161CGHG3CkkQYYMoCgEhNtHLPMM8csZ5EnnoziAzTopMPOpu/AQw8f
fdQhhxtzsJFGGF9oQcUQKSR0xCn+vxDDCySNPGLrI43k2sgW1tQzDz788CMfJn/I4cYcbKQRxhda
gNEFEkikkIBBPFyBiy6wADLIttx2y8c2+/Ajn3yY9AEHG2mE8YUWYHRBxRNNyvABAAYNccoslZCp
77766oEgHGmwMQcchqYRxhdcaNFFF1RA8YRpKTiAUA1+fDJHSRhn/IQX7qDTDjw94cOPP89EsnBb
UDTGg2Q6hLAAAArFQIUbSNVssxrC5HMPP+OGM4ocjT2hhA4+1iADBwoAMNwJLCixcFtQU+Ghh0Ej
AYRkRcvQQQYFACBlQQx8EEIIKbAQw9kspBACBxxowEABAHwt99x0161kEqEpcQX+GW20gQYURAzx
AxB2F+QEEnHocswwwABzGy+64DJLKqdU7ggVPNBA9xRIJJLMMctMdIwsnTxiSXqGDPJHH2TqUYcc
dXShAwxLToEELMc9A4xFpNTAgw8+FJFEElZksUUadehRhxxuwMFGGDWsMBwSjhwXjSqSkoICMuWQ
Q4456ITvjhp66FGHHG7AkQZST8QQgUpE1LJMMtHsIulyNyBjzjjmpLMpO/LYgyDqIIeSwCENYfgC
F6AQAwoohAivMMYynrEKSo3CE6PwhCQ8UQRobOod8IBHT/KxiD/UQQ5umAMb0hCGL3CBCk9gwQMQ
QoRABIMYzgDFI2xik1s9Ygr+1KhHT+yBj2D5AxOAkENJ4JAGpHBBC11Qwg9ScICDHEEXvygGKyCh
qy5CohFmuMY98BEswxgGE38oCRzSgBQuaKELVCACElggAYMEgQq68IUvBmGI9aTHEICkQzb2wQ8z
mhETfXADHNKAFC5oYWFQaJIMNGCQH1wBF7k4xR8AAYhucfIqheBGPwxpxlEIgg1pQAoXtLAwKihh
CD+QgQgAUBAaIIEWs8iEILbCS16SyRM1CqYwSSEIpHxhRV1oCxSGUBoWWAAABtGBI2LhiPLxSxDl
q4Me3BAFHxQhCVPIAhvgkAakcEELYOgCFTxEBNOEAAEHqQERRJEIOdjznvj+nMMNGIGOdrADHvO4
Rz6wsQg5aAEMXWgLFJ5ABJaxQAMBQIgMnvCJOVh0DhizqBuScItNvWMe9sBHsPxxDkxwoS1QaMwP
dFADHcSAAwVQSAuI4IeC2TQNYeBCIOgBj3nggx+GrAYmPNQYJeigBkhlwQYIoJIRxEALYfiCVKfK
BS6kgQ+v6AY/DLOOZ4ziD0FDgg6QitQOVEAAwzFBDKigBTC4dWFwpUIX2OAGOHThCVF4AhJ4QFak
hiADBQDAkjzAAh5AIWpTg8IToqCEH/CAZWRlAQcqMAAA0G0CIVBBDHhAhCb9YAim4YEOZJCCDmwA
AgQAQOEIYgAEOMACGNATgAYwUAEHIMAAAQDAanfLW94GBAA7
}

    image create photo errorImage\
        -format gif\
        -data {
R0lGODlhQAAwAOf/AAABAAgAABABATMAADsAAEUBAEsAAFgBAmAAAXEAAG4CAH4AAngCAGgHAogA
AYMCAI0AAJMAAW0NAJgBAKAAAZAGAK0AAqUEAJUNALEFALsEAr0IA6oOALMMANIDAL4LALUOAMAO
ALYRALcTAMERAMsOAsMUANcPAM4UAMUXAMYZANAYANoWA9IbAMoeAPATAN0aANQdANUfAOgaAv0V
AN8eANchAtgiAOEgAOIiAOwgAPYeAeQkAO4iAO8kAOYnAvgiA+coA/AmAOgpAPEoAOorAOkrBfMp
APwnAPQrAfcuA/8sAOYzEPgwAP8uAOo3CPszAP83APc5Bf85APA9D/86Af86D/o9Cv1ADe9FGv9C
D/dEFv9EEexKIvZLIP9LEvZMKP9MFP9MHvFQJ/RRIPpPI+5UJuZVN/NSL/5SHf9UH/lWJfpXLf9W
KfNZMv9bKf5bMP9cK/9eLPRhNPlfPftgN/5hK/1hMv9jM/hkPv9kNP9lPP9qNv5qPP9qQ/9rPvtt
PN5zX+1yWP9wP/ZyUP9yQPlzS/9yRux3Wv9zTv90SP53Qf94Sf95UP96S/l7W/96V/J+Zv19Uf9+
TP9/Wf+AU+qEbP+DXP+DYvaGZf+FVf+GYtuOhP+JZOyNd/6MZeKThPuQbP+Pbf6SaP+VcOyahf+W
d/+Wff6Zcv6beeKhkvqef/iehf+de/+efN+nm/6hff6ig/+khf+lh/Sql/6ph/irk/+rj9qzruS0
q927rv+0oerAtv+8ptzFwfq/s+bGv//CqvvGsfbLwf/Lvf3RwN7Y19ja193a39je4Oja29Dg5//V
ytze2trf4t7g3dfk5dTl697j5uHj4Ofi4OPl4tfo7+Ln6tzp6vzi2Ovm5Obo5efq5ubr7uDt7unr
6Ors6f/n3fDr6fnp49/w9unu8ezu6+Xy8+/x7vjv6Ozy9Of09fbx7+X1/PHz8PD1+P/y7PP18uv5
+fv19PP4+/b49fX7/fD9/vn7+Pr8+fv9+v/8+vn+//z/+/7//P///yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAgAAAAwADAAQAj+AP8JHEiwoMGDCBMq/NfDUK1YsWrdGsWIkaJCf/7o0ROn
oxo1YsJwGWllSpERCwXmoJQqVSxFhQopWvSnBrlq27h1U5dETZgr8/jl80eUWJgpSKdASUKkRYsL
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
0K1cQAAAOw==
}

    image create photo warningImage\
        -format gif \
        -data {
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
0EACQNCCGvSgCE1oQgXK0IY69KEQjahEHRoQADs=
}

    image create photo questionImage\
        -format gif \
        -data {
R0lGODlhQAAwAOf/AAABAAACBgQBBgYDCQkGCwwJDgoLFQ4MEBENGw4OIA4PFxESIxUSHxQUHBUU
KhoVJxgXLRcYKRsZJh0aNh4cKRscPB8gMR4fQCEhQiAiPh0iSCMkNSUjOikmNCcnSSMoTionTycp
RSkqPCYrQSssPi0qUi8tRS4tUCouVS0uXDAxTjMxSTMwWTM0Rjg2Tjc3SjU5UTs4UTo7Tj47VT88
VTs/VkA+YkBAUz9AXj1CZUJDVkZEaEVFZEhKdExMa0hNcVFOdE5QelRRd1NTclFTflVWdVtYclZa
c1lahltccF1agWFehWFhdl9gjGJgk2ViiWFlfmJjj2Zjl2hlgGJnmWZnlGhmmWVpj21pkWtvlW1u
mnBtoW5vqXNxpXVypnV1lnl2qnl5p3t4rXV6rYF9mn19q398sXl+sXt/soSAnYGBr4KCo32CtYSB
tn+Dt4iEoYCFuIaGqIiFu4OIvIqKrIqKuI2Jv4eLv42Mu4mNwY2RuY6Sx5KSwZWVt5GVypaWxZSY
zZmZvJ2ZtpmZyJaaz5ubyp2cv5yg1Z6hyqCg0KOi0qGk2qWk1KOm3Kio2Kqp2qaq4Kur262s3a6u
3q+v362w5rGw4bOy47G067W05ba15rO34Le26LS37rm43ba54rm46rq567a68b655by77Li888G8
6L6977q+9cC/8L7B68HA8cLB88XB7cPC9MDD+8TD9cjD78LF78XE9sbF98rF8cfG+MPH/sTI8sjH
+cnJ7crI+sfK9MvK/MzL8M/K98nM98zL/c3M/s7N/8/O88zP+c/O/9PO+tDP/87R+9LR9tXQ/NbR
/tDT/dTT+NfT8tHU/9LV/9bV+tPW/9TX9NfW+9rW9dTX/9nY/drZ/t3Z+Nva/9zb/9rd+93c/97e
9uLd/dzf/ePe/uDg+N7h/9/i/+Li+uTj++Dk/+fk9uXl/efn/ujo/+bq++np/+rq/+/r/fDs/uvv
/+zw/+3x/+7y//Hy/PLz/fP0//X1//b2//r3/Pv4/fz6/v77/////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAgAAAAwADAAQAj+AP8JHEjwkiVKkyRJcqRoEMGHECNG5KTMn799+fLNW1eO
XDhw3LYZcfAA2jJjw4LlouXKGikzBGPKjPmHE7ds2bBN2xkNGhMBAhAJC7bL1ixX1s5RE+UHiYCZ
UKMKlAOLVi5laBoQfKVtn799Ge3FK0dO3IkJIXZCW2ZsWLBctFwpaxO17kBL4LbpzYZtZzRoQAMM
E9YrFy1Xq0rFOvfISYCYkCNLnrxlUShOz+70ADD5H6x1/Pzxy3dvnjx47NaJ24ZtWjRmxoYJ63Uo
TOfbj6rNm1eOHDlx4LjpfZOAQTJmxowNC5bLFqxVwNKFurPitnU1mpYl57Yt+bBeuVb+YTrUZtGs
c/by7ct3b148eOzWidsJbdkwSXisxwRiZcsGgZzwMg8/+cBTDjnigMONXjUgIAM0yxgzzDC72ALL
KqVQs0kT+t1WRB2KkLIMM8kNE8wutszCSiqpfAMKGEQQ0OGMkm3hhRU7FADAjLe4Yg089uRzjz3z
xAMPO+Vgs9Msj/hB42SvaGORPxnZMw88JXygwQUVTPBFNMwkJ0wvufzCyh1PDmRJOP7sk88965Tj
GzjcbKPLEQssYMgyxgwTzC62wILKOansQcNtknFCDjjcNKpXNthM00wxwByTnDC95EKLK6kok04r
j1AhAKKTFYILNtNAAw0zy2yDzTT+0DQDTTXdnHOONaxgssginbCCiy/KEAOMLKZcwsggfBCk7LJ5
DNPLLtkMM0cHCihQgAAA6AHMPRZlZM888cCTAgggZLMTNMsYI0wwu5DSxrLLXgEHJ7QA8gNBstjj
zz4ZxVNOOeSAw40LDqwwDTTLJCfMLrbAkooykiAB78TKalIOOeKIA06j22SDzTRpJEFGcsMEk4st
sKxyCivn7IEDxTAPxEcm2OwUDTTMLJPcMML0kgstsLBSCzHjKHOHEAHErDS8LfigxBNPLLFFKKeE
ogo1bZiw9NZLb6GJKo5YYQEAXJdtNtevkOIKMc5oA0432UgDTCuZLHLI2Uqjoo3+Pfnwk9E88sDD
DjvlbDNNNMwsswwrhayBt7KpsGPRPhnZMw8dQbDwgQ1xRDMNNMsYM4wwu+RCCBaP/8NKPv7wk9E9
87BTzg59eBJIBhBwEA0zyQmziy3A5NJIFXhn0o0//GRkzzrl+AYON9tU48ICMDCTnDC95DLLKt+k
cgcJZ1cSjj/75LNOOb6B06ggESQggiHMJCdML7nM4koq7aSyBw1nK+JLOb4RBzgapRdsxIEBEmDG
MowxDGHswhazYEUqxkENUYhBAnhbRDW4oZdtZAMbO5kGFAhAAEQYQxjByIUtYLEKZaRDGaJwQwwA
8LhByGIbIYxGNJixjOQYQxj+wdgFLWihDFsRQxR+kMINppCISlyiEpA4hNn4cAloKM4Y01iHFm11
jnBUoxiw4EQlOoGLbrBDHmiMBzzYsQ5yYGMau7gEIOqgtCwwIjnCAMcyDuEGN6BhDF6QAhAkUYx5
7IMfGbHHPOIxuHJwYyfQWEZyhhGKO8TMDZIIhi2ccQw0HEBZrJiHRfiRj3vMQx7sKAcKMOABbEwj
GsxIjjB2YYteOEILMNNCHlyxCmXMQQQEOYU8/MGPjNwjHuXwDThUAAETTCMazEiOMHqRi1msQhqA
4EHMhuCFPSyiCgQBhj38kRF4lMM34ODGNmKwgBdEgxnJGUYvckELV6RCGZ/wiALXNjCCgchiHflg
h2/EAQ5u6AUbOjDADZiRHGH0Ihe0cEUqSjEORhDhcY2QhjgaxQ29ZAMbO5GFLFRhjGEEYxe2mAUr
UlGKZygDDBQQiExnStOa/uMPo+BGNrARwmhAYxkCAAAAhNGLXNACFqs4hSu+4QswkAAANo1qVNWg
CFxMIxrM8OEwgrGLXNACFqxIxTioEQs7IIEAUk2rVH1QhjsQohGTuAQlLEEJV6SCFKn4BiGCEAC1
+vWvMq3CI0LRCV+oQgoHAKxi1coFSWBCF49wwgEWS9moooETdXCCBQBQ2c7OlAo5KAAAPEvazgYE
ADs=
}

    image create photo preferencesImage\
        -format gif \
        -data {
R0lGODlhFAAUAOfxAK8OBwQ5aQM/eAY/dLgbEgdHgsEjFAhPkLsqIcgqG9crEgpaocczI6s7OLo5
L+EyFA1ir8M7KQ5mswZoxb9AMwdpxMBCOMFCPRBrugltywpwzuRBIRJwwg1xztBIOQ1zz+FFLKdU
SRF0zhB20BN2yhV3yRV3zxN50Bp6zxZ80cpXQq1dXBl+zxl/0h2B0RyC0yeBzx+E0h6F07tjWyGH
1CKH09JiUi6IwSWK1CWK1SeM1SiN1TmJzyqP1SuQ1kOLzTmO0y2S1i6T1zCT1MxxaTGW2GKNtUuS
zzSY2NB4cTWc2zec2TWd3LiAe5yIhjqe2jqf2jyg2Tyh2j2h2jyi3D2i3Oh7aF2azz2j3T2j3raJ
gVqe1T6n4z+n4l2i102q4G6jztyLe2Gm2qCcnLOalmaq3FWv4lev4nynzX6nzn6pzn+pztmVk36q
z2yv34Cs0IGs0IGtz2G15IKu0IOv0HCz4nmz2ISx0ISx0bSoqIWy0Wq55nK35MCnppKxzXW55oi2
1He753K957GxsXi9596nonu/6LS0tHrA6aG4zbW1tbW2tre2tn/C6be3t4DD6oDE6rq4t4HE6oLE
6ry4t7q6ut+yrLC/zb29vd21sM65t76+vozJ7L2/wMDAwMfAv8PDw77HzsLKzubCwM3JyNHJyc/K
yczNzs3Nzd7Jx8/Nzc7Ozs/Ozc/Pz9HPztDQ0NDR0ejLx9HR0dLS0tPS0tPT09LU1NTU1M3W3NTV
1dXV1dbV1O/PytXW1tbW1tfX19jY2NnZ2dra2tva2dvb29vc3Nzc3N3d3d7d3d7e3t/e3erc2t/f
3+Df3+Hf3t/g4OHh4eHi4uLi4ebh4OLi4uPj4/Hg3OTk5Obm5ebm5ujo6Orp6erq6uzs7O3t7O3u
7u/v7/Dw8Pbw7/Ly8u/z9fPz8/X19fb29vT3+fj4+Pf5+vn5+fn6+/v7+/z8/P39/f7+/v//////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JzFJlSpSDUaR04SKwoUMkgcp1E+apVJ5ZjKyYEjZH
hsN/LrbsmkVLFStXp0JdSuTnR4WPWCS1S8fLA6VONiJ8onZMT4+PO9xggzZrhoUkDsYA+3VLzQmY
j+C9c8dOHTpysTaIwmVnyEcohs6NK6YJAYEmi6hBM3Ynx0chfLxlm2YpGrNMCrT0+vWmxccaYpQR
QwVr1IpvlWrVepXmw8d/JUhwwCABwoIDBQYEeCwQixlOkxAJ2iPnzBcjT5gouQETkrt14qyNA7cM
hApbyQAF+UilUTpzyCgQKWTASTVqxvDo+LiEkDlwwXyxafAMk7NmxOjQ+FjkTzhu2oBc6dKVK8wD
UMDivPjoo862a6kSkInEIESrYLrapPiIo4y0ZK+QcgEAfTgy3ixrjPBRDF4MA8wrimwyyCGOyPLK
Kmho8BELQMABxhVH8AADCiaI0EEGEwjA2YorBgQAOw==
}

    image create photo automergeImage\
        -format gif \
        -data {
R0lGODlhFAAUAOeEAAAAAAICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQ8PDxERERQUFBUVFSMjIyQk
JCUlJScnJygoKC8vL0cwAUkwADIyMjU1NU45BTo6Ojs7Ozw8PFI8AD09PUJCQkdHR25QCFhXVnNe
F4FdA3ZgGmBgYIFgD3llMG1tbXFxcXh4eH5+fn9/f6KCIKqED4SEhKqGF7WKFI+Pj7yPC8CPALqZ
I76aI8afFMqfDcSfIr6hMdOhBKGhocyiKs2lJKWlpcanWqurq8WvRtixIbCwsLGxsd2zH9S2N9e4
Mty4Kdq5Md+5J7e3t9+6KuW8INm9QLq6uui9Fbu7u9u/OLy8vMDAwN3FTcPDw8PFzOjLP+XQUfDR
OObRWs7Oz//TF9vPq/jUKu7VTP/VGtHR0f7XIt3Tu9TU1OXabPLaS//aJtXV1fbdS9jY2PjfT9vb
2/fkY9/f3/7lTuDg4N/g5P7mUP/nReLj5fTpd//sUv3rY//tUvvsa+bm5v/uYevr6+zs7P/4hfLy
8v/5iPj4+Pn5+f//////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjaAP8JHEiwoMF/LEJsqGFmIJE1ffbUIePFhMApgJ44OEDg
wMGPUMbg+aNlxkAjUl6I+CgwAgYIAgAAaEBCA0uBSmgMFKLmjhOWdviE+ZJjAsEoV3icOXLzQQcX
g96IWbLjRMETHiQMkGmgwM1/MVJk+EqWYBIcPT4i0VFETxCBMpjAyQPmw8EbbALN6UKnikAYIwi2
ILjFTRM0WSgQ5JJGzg8sNi4cLCEwQRRBguK0ARQHBMsKGA4wAGLFBwqWFjgskDngAACWVFQokBkA
QYCvQ/yUWeGgrO+PAQEAOw==
}

} ; # Load_Images

#===============================================================================

program bits_driver
implicit none
write(*,"(*(l1,1x))")btest([0_4,1_4,-1_4,53_4,-45_4,2147483647_4,(-2147483647_4-1_4),-2147483647_4],31_8)
end program

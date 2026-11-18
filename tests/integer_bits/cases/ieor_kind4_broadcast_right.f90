program bits_driver
implicit none
write(*,"(*(i0,1x))")ieor(5_4,[0_4,1_4,-1_4,53_4,-45_4,2147483647_4,(-2147483647_4-1_4),-2147483647_4])
end program

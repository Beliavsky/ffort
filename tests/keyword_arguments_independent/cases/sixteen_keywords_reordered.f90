program keyword_oracle
implicit none

print *,combine(p16=16, &
p15=15, &
p14=14, &
p13=13, &
p12=12, &
p11=11, &
p10=10, &
p09=9, &
p08=8, &
p07=7, &
p06=6, &
p05=5, &
p04=4, &
p03=3, &
p02=2, &
p01=1)
contains
integer function combine(p01,p02,p03,p04,p05,p06,p07,p08,p09,p10,p11,p12,p13,p14,p15,p16) result(result_value)
integer,intent(in) :: p01,p02,p03,p04,p05,p06,p07,p08
integer,intent(in) :: p09,p10,p11,p12,p13,p14,p15,p16
result_value=p01+p02+p03+p04+p05+p06+p07+p08+p09+p10+p11+p12+p13+p14+p15+p16
end function combine

end program

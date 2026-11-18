program keyword_oracle
implicit none

print *,777
print *,combine(p17=1, &
p16=1, &
p15=1, &
p14=1, &
p13=1, &
p12=1, &
p11=1, &
p10=1, &
p09=1, &
p08=1, &
p07=1, &
p06=1, &
p05=1, &
p04=1, &
p03=1, &
p02=1, &
p01=1)
contains
integer function combine(p01,p02,p03,p04,p05,p06,p07,p08,p09,p10,p11,p12,p13,p14,p15,p16,p17) result(result_value)
integer,intent(in) :: p01,p02,p03,p04,p05,p06,p07,p08
integer,intent(in) :: p09,p10,p11,p12,p13,p14,p15,p16
integer,intent(in) :: p17
result_value=p17
end function combine

end program

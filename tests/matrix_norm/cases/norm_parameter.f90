program p
implicit none
real,parameter::v=norm2([3.0,4.0])
if(v/=5.0) error stop 1
end program

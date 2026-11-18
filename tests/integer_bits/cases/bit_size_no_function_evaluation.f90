program p
implicit none
if(bit_size(draw())/=64_8.or.kind(btest(draw(),position()))/=4)error stop 1
print *,0
contains
function draw() result(x)
integer(8)::x(2)
error stop 9
x=1_8
end function
integer function position()
error stop 9
position=0
end function
end program

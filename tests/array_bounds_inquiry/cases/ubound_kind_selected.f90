program p
implicit none
integer,parameter::rk=8
real::x(-2:0,5:6)
integer(8)::b(2)
b=ubound(x,kind=selected_int_kind(18))
if(kind(ubound(x,kind=selected_int_kind(18)))/=8)error stop 1
if(any(b/=[0_8,6_8]))error stop 2
end program

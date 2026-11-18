program p
implicit none
integer,parameter::ik=8,rk=kind(1.0d0),sk=selected_int_kind(15),sr=selected_real_kind(15)
integer(ik)::a(0)
real(rk)::b(0)
a=[integer(kind=ik)::]
b=[real(rk)::]
if(kind([integer(sk)::])/=8) error stop 1
if(kind([real(sr)::])/=8) error stop 2
if(size([integer(ik)::])/=0) error stop 3
print *, 'PASS' 
end program

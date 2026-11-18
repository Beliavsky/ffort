program p
implicit none
integer,parameter::sp=4,dp=2*sp
real(8)::undefined
print *,aint(-3.1,dp),anint(3.1d0,sp)
print *,aint(a=2.75,kind=kind(undefined)),anint(a=2.75,kind=selected_real_kind(15))
end program

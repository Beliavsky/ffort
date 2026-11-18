program p
implicit none
integer,parameter::k=4
print *,kind(maxloc([1,3],kind=2*k)),minloc([3,1],kind=selected_int_kind(15))
end program

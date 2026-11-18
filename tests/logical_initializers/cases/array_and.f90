program p
implicit none
logical,parameter::a(2)=[.true.,.false.]
logical,parameter::b(2)=a.and..true.
print *,b
end program p

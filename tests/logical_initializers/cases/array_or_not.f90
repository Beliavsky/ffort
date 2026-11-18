program p
implicit none
logical,parameter::a(2)=[.true.,.false.]
logical,parameter::b(2)=a.or..not.a
print *,b
end program p

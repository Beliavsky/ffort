program p
implicit none
logical,parameter::m(3)=[.true.,.false.,.true.]
integer::a(3)=1
where(m) a=7
print *,a
end program

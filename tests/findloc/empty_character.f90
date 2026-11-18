program p
implicit none
character(0)::a(3)
a=''
print *,findloc(a,''),findloc(a,' ',1,back=.true.),findloc(a,'x')
end program

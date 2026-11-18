program p
implicit none
logical::a(4)=[.false.,.true.,.false.,.true.]
print *,findloc(a,.true.),findloc(a,.false.,1,back=.true.)
print *,findloc(a,.true.,[.true.,.false.,.true.,.true.],back=.true.)
end program

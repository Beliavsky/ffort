program p
implicit none
integer::a(4)
a(2)=9;a(4)=9
print *,findloc(a,9,mask=[.false.,.true.,.false.,.true.],back=.true.)
end program

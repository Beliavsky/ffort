program p
implicit none
character(len=2) :: a(3),b(3),c(3)
a=['aa','bb','cc']
b=['xx','yy','zz']
c=merge(a,b,[.true.,.false.,.true.])
print '(3a2)',c(1),c(2),c(3)
c=merge('ok',b,[.true.,.false.,.true.])
print '(3a2)',c(1),c(2),c(3)
print '(a)',merge(tsource='yes',fsource='no ',mask=.false.)
end program

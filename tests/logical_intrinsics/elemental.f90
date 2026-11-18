program p
implicit none
integer :: a(2,2)
logical :: mask(2,2)
a(:,1)=[1,2]
a(:,2)=[3,4]
mask=a>2
print *,merge(a,0,mask),merge(9,a,.false.)
print *,merge(.true.,.false.,mask)
print *,merge(tsource=1_8,mask=.false.,fsource=9007199254740993_8)
print *,dble(a),kind(dble(a)),dble(a=9007199254740993_8)
print *,dble(1.2345678901234567d0),kind(dble(1.0))
end program

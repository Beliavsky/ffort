program p
implicit none
character(60)::text
integer::n,a(3),stat
real(8)::x(2)
text='3 -2 4 6 1.25D0 -2.5'
read(text,*,iostat=stat) n,a,x
if(stat/=0.or.n/=3.or.any(a/=[-2,4,6]).or.any(x/=[1.25d0,-2.5d0])) stop 1
print *,1
end program

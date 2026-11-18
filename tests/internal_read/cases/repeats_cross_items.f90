program p
implicit none
character(50)::text
integer::a,b(2),stat
real(8)::x(2)
text='3*2,2*1.5'
read(text,*,iostat=stat) a,b,x
if(stat/=0.or.a/=2.or.any(b/=2).or.any(x/=1.5d0)) stop 1
print *,1
end program

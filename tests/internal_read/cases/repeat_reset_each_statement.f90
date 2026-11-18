program p
implicit none
character(10)::text
integer::n,stat,k
text='9 10'
do k=1,3
read(text,*,iostat=stat) n
if(stat/=0.or.n/=9) stop 1
end do
print *,1
end program

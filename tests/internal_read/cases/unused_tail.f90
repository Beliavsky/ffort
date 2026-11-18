program p
implicit none
character(30)::text
integer::n,stat
text='5 this is not read'
read(text,*,iostat=stat) n
if(stat/=0.or.n/=5) stop 1
print *,1
end program

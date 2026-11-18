program p
implicit none
character(20)::text
real(8)::n
integer::stat
text='Infinity'
read(text,*,iostat=stat) n
if(stat<=0) stop 1
print *,1
end program

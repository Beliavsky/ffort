program p
implicit none
character(80)::text
real::n
integer::stat
text='1e100'
read(text,*,iostat=stat) n
if(stat<=0) stop 1
print *,1
end program

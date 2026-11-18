program p
implicit none
character(80)::text
integer::n
integer::stat
text='2147483648'
read(text,*,iostat=stat) n
if(stat<=0) stop 1
print *,1
end program

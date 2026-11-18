program p
implicit none
character(80)::text
integer::n
integer::stat
text='9223372036854775808*1'
read(text,*,iostat=stat) n
if(stat<=0) stop 1
print *,1
end program

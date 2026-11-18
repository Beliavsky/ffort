program p
implicit none
character(80)::text
integer::n
integer::stat
text='abc'
read(text,*,iostat=stat) n
if(stat<=0) stop 1
print *,1
end program

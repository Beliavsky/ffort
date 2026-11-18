program p
implicit none
character(10)::text
integer::a(2),stat
text='1'
read(text,*,iostat=stat) a
if(stat>=0) stop 1
print *,1
end program

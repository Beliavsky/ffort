program p
implicit none
character(4)::text
integer::a(0),stat
text=''
read(text,*,iostat=stat) a
if(stat/=0) stop 1
read(text,*,iostat=stat)
if(stat/=0) stop 2
print *,1
end program

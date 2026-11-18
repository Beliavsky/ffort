program p
implicit none
character(10)::text
integer,allocatable::a(:)
integer::stat
text='1'
read(text,*,iostat=stat) a
print *,1
end program

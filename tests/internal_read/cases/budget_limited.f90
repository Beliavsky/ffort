program p
implicit none
character(100)::text
integer::a(20),stat
text='20*4'
read(text,*,iostat=stat) a
print *,1
end program

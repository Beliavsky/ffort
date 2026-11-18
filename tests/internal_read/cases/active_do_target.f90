program p
implicit none
character(10)::text
integer::n,stat
text='1'
do n=1,2
read(text,*,iostat=stat) n
end do
end program

program p
implicit none
character(10)::text
integer::n,stat
text='1'//achar(10)//'2'
read(text,*,iostat=stat) n
end program

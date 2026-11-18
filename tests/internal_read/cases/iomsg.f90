program p
implicit none
character(10)::text,msg
integer::stat,n
read(text,*,iostat=stat,iomsg=msg) n
end program

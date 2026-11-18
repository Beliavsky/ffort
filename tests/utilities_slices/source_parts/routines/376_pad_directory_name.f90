subroutine pad_directory_name(dir_name,dir_sep)
! append dir_sep to dir_name if dir_name does not already end in dir_sep
character (len=*), intent(in out)       :: dir_name
character (len=1), intent(in), optional :: dir_sep
integer                                 :: len_dir
character (len=1)                       :: dir_sep_
if (present(dir_sep)) then
   dir_sep_ = dir_sep
else
   dir_sep_ = directory_sep()
end if
len_dir = len_trim(dir_name)
if (len_dir < len(dir_name)) then
   if (dir_name(len_dir:len_dir) /= dir_sep_) dir_name = trim(dir_name) // dir_sep_
end if
end subroutine pad_directory_name
!

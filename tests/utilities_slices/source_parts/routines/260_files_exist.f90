function files_exist(xfiles,dir,suffix,print_missing) result(tf)
character (len=*), intent(in) :: xfiles(:)
character (len=*), intent(in), optional :: dir,suffix
logical          , intent(in), optional :: print_missing
character (len=1000)          :: dir_,suffix_,xfile
logical                       :: tf(size(xfiles))
logical                       :: print_exist_,print_missing_
integer                       :: ifile
print_exist_ = .false. ! .false.
print_missing_ = default(.false.,print_missing) 
call set_optional(dir_,"",dir)
call pad_directory_name(dir_,merge("/","\",unix()))
call set_optional(suffix_,"",suffix)
! print*,"dir_=",trim(dir_)
do ifile=1,size(xfiles)
   xfile = trim(dir_) // trim(xfiles(ifile)) // trim(suffix_)
   tf(ifile) = file_exists(xfile)
   if (print_exist_) write (*,"(l3,1x,a)") tf(ifile),trim(xfile)
   if (print_missing_) write (*,"(a)") "missing " // trim(xfile)
end do
end function files_exist
!

subroutine copy_file(xfile,yfile,out_unit,max_copy)
! copy contents of xfile to yfile
character (len=*), intent(in)               :: xfile,yfile
integer          , intent(in)    , optional :: max_copy
integer          , intent(in out), optional :: out_unit
character (len=10000)                       :: text
integer                                     :: ierr,iu,ou,icopy
if (xfile == yfile) then
   write (*,*) "in copy_file, input and output files are both " // trim(xfile)," RETURNING"
   return
end if
ou = default(bad_unit,out_unit)
if (ou == bad_unit) call get_unit_open_file(yfile,ou,xaction="w",nlines_skip_append=0)
call get_unit_open_file(xfile,iu,xaction="r")
icopy = 0
do
   icopy = icopy + 1
   if (present(max_copy)) then
      if (icopy > max_copy) exit
   end if
   read (iu,"(a)",iostat=ierr) text
   if (ierr /= 0) exit
   write (ou,"(a)") trim(text)
end do
if (present(out_unit)) out_unit = ou
end subroutine copy_file
!

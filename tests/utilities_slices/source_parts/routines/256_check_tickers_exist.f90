subroutine check_tickers_exist(tickers,dir,suffix,good_ticker_file)
character (len=*), intent(in)           :: tickers(:)
character (len=*), intent(in), optional :: dir,suffix,good_ticker_file
character (len=1000)                    :: dir_,xfile
character (len=100)                     :: suffix_
integer                                 :: i,ntickers,nmiss
logical                                 :: xexist(size(tickers))
ntickers = size(tickers)
call set_optional(dir_,"",dir)
call pad_directory_name(dir_,merge("/","\",unix()))
call set_optional(suffix_,"",suffix)
do i=1,ntickers
   xfile = trim(dir_) // trim(tickers(i)) // trim(suffix_)
   xexist(i) = file_exists(xfile)
   if (.not. xexist(i)) write (*,*) trim(xfile)
end do
nmiss = count(.not. xexist)
if (nmiss > 0) then
   write (*,"('#missing files = ',i0)") nmiss
   if (present(good_ticker_file)) then
      call write_lines_file(good_ticker_file,pack(tickers,xexist),format_str="(a)")
      write (*,"(a)") "wrote good tickers to " // trim(good_ticker_file)
   end if
   stop "program stopped because of missing files"
end if
end subroutine check_tickers_exist
!
